//+------------------------------------------------------------------+
//|                  EA31337 - multi-strategy advanced trading robot |
//|                       Copyright 2016-2020, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

/**
 * @file
 * Implements Awesome strategy based on for the Awesome oscillator.
 */

// Includes.
#include <EA31337-classes/Indicators/Indi_AO.mqh>
#include <EA31337-classes/Strategy.mqh>

// User input params.
INPUT string __Awesome_Parameters__ = "-- Awesome strategy params --";  // >>> Awesome <<<
INPUT int Awesome_Shift = 0;                     // Shift (relative to the current bar, 0 - default)
INPUT int Awesome_SignalOpenMethod = 0;          // Signal open method (0-1)
INPUT double Awesome_SignalOpenLevel = 0.0004;   // Signal open level (>0.0001)
INPUT int Awesome_SignalOpenFilterMethod = 0;    // Signal open filter method (0-1)
INPUT int Awesome_SignalOpenBoostMethod = 0;     // Signal open boost method (0-1)
INPUT double Awesome_SignalCloseLevel = 0.0004;  // Signal close level (>0.0001)
INPUT int Awesome_SignalCloseMethod = 0;         // Signal close method
INPUT int Awesome_PriceLimitMethod = 0;          // Price limit method
INPUT double Awesome_PriceLimitLevel = 0;        // Price limit level
INPUT double Awesome_MaxSpread = 6.0;            // Max spread to trade (pips)

// Struct to define strategy parameters to override.
struct Stg_Awesome_Params : StgParams {
  unsigned int Awesome_Period;
  ENUM_APPLIED_PRICE Awesome_Applied_Price;
  int Awesome_Shift;
  int Awesome_SignalOpenMethod;
  double Awesome_SignalOpenLevel;
  int Awesome_SignalOpenFilterMethod;
  int Awesome_SignalOpenBoostMethod;
  double Awesome_SignalCloseLevel;
  int Awesome_SignalCloseMethod;
  int Awesome_PriceLimitMethod;
  double Awesome_PriceLimitLevel;
  double Awesome_MaxSpread;

  // Constructor: Set default param values.
  Stg_Awesome_Params()
      : Awesome_Shift(::Awesome_Shift),
        Awesome_SignalOpenMethod(::Awesome_SignalOpenMethod),
        Awesome_SignalOpenLevel(::Awesome_SignalOpenLevel),
        Awesome_SignalOpenFilterMethod(::Awesome_SignalOpenFilterMethod),
        Awesome_SignalOpenBoostMethod(::Awesome_SignalOpenBoostMethod),
        Awesome_SignalCloseMethod(::Awesome_SignalCloseMethod),
        Awesome_SignalCloseLevel(::Awesome_SignalCloseLevel),
        Awesome_PriceLimitMethod(::Awesome_PriceLimitMethod),
        Awesome_PriceLimitLevel(::Awesome_PriceLimitLevel),
        Awesome_MaxSpread(::Awesome_MaxSpread) {}
};

// Loads pair specific param values.
#include "sets/EURUSD_H1.h"
#include "sets/EURUSD_H4.h"
#include "sets/EURUSD_M1.h"
#include "sets/EURUSD_M15.h"
#include "sets/EURUSD_M30.h"
#include "sets/EURUSD_M5.h"

class Stg_Awesome : public Strategy {
 public:
  Stg_Awesome(StgParams &_params, string _name) : Strategy(_params, _name) {}

  static Stg_Awesome *Init(ENUM_TIMEFRAMES _tf = NULL, long _magic_no = NULL, ENUM_LOG_LEVEL _log_level = V_INFO) {
    // Initialize strategy initial values.
    Stg_Awesome_Params _params;
    if (!Terminal::IsOptimization()) {
      SetParamsByTf<Stg_Awesome_Params>(_params, _tf, stg_ao_m1, stg_ao_m5, stg_ao_m15, stg_ao_m30, stg_ao_h1,
                                        stg_ao_h4, stg_ao_h4);
    }
    // Initialize strategy parameters.
    AOParams ao_params(_tf);
    StgParams sparams(new Trade(_tf, _Symbol), new Indi_AO(ao_params), NULL, NULL);
    sparams.logger.Ptr().SetLevel(_log_level);
    sparams.SetMagicNo(_magic_no);
    sparams.SetSignals(_params.Awesome_SignalOpenMethod, _params.Awesome_SignalOpenLevel,
                       _params.Awesome_SignalOpenFilterMethod, _params.Awesome_SignalOpenBoostMethod,
                       _params.Awesome_SignalCloseMethod, _params.Awesome_SignalCloseMethod);
    sparams.SetPriceLimits(_params.Awesome_PriceLimitMethod, _params.Awesome_PriceLimitLevel);
    sparams.SetMaxSpread(_params.Awesome_MaxSpread);
    // Initialize strategy instance.
    Strategy *_strat = new Stg_Awesome(sparams, "Awesome");
    return _strat;
  }

  /**
   * Check strategy's opening signal.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, double _level = 0.0) {
    Indi_AO *_indi = Data();
    bool _is_valid = _indi[CURR].IsValid();
    bool _result = _is_valid;
    double _level_pips = _level * Chart().GetPipSize();
    switch (_cmd) {
      case ORDER_TYPE_BUY:
        // Buy: 1. Signal "saucer" (3 positive columns, medium column is smaller than 2 others).
        // 2. Changing from negative values to positive.
        _result = _indi[CURR].value[0] > _indi[PREV].value[0];
        if (METHOD(_method, 0)) _result &= _indi[PREV].value[0] > _indi[PPREV].value[0];
        if (METHOD(_method, 1)) _result &= _indi[PPREV].value[0] > _indi[3].value[0];
        if (METHOD(_method, 2)) _result &= _indi[CURR].value[0] > 0;
        if (METHOD(_method, 3)) _result &= _indi[PPREV].value[0] < 0;
        break;
      case ORDER_TYPE_SELL:
        // Sell: 1. Signal "saucer" (3 negative columns, medium column is larger than 2 others).
        // 2. Changing from positive values to negative.
        _result = _indi[CURR].value[0] < _indi[PREV].value[0];
        if (METHOD(_method, 0)) _result &= _indi[PREV].value[0] < _indi[PPREV].value[0];
        if (METHOD(_method, 1)) _result &= _indi[PPREV].value[0] < _indi[3].value[0];
        if (METHOD(_method, 2)) _result &= _indi[CURR].value[0] < 0;
        if (METHOD(_method, 3)) _result &= _indi[PPREV].value[0] > 0;
        break;
    }
    return _result;
  }

  /**
   * Check strategy's opening signal additional filter.
   */
  bool SignalOpenFilter(ENUM_ORDER_TYPE _cmd, int _method = 0) {
    bool _result = true;
    if (_method != 0) {
      // if (METHOD(_method, 0)) _result &= Trade().IsTrend(_cmd);
      // if (METHOD(_method, 1)) _result &= Trade().IsPivot(_cmd);
      // if (METHOD(_method, 2)) _result &= Trade().IsPeakHours(_cmd);
      // if (METHOD(_method, 3)) _result &= Trade().IsRoundNumber(_cmd);
      // if (METHOD(_method, 4)) _result &= Trade().IsHedging(_cmd);
      // if (METHOD(_method, 5)) _result &= Trade().IsPeakBar(_cmd);
    }
    return _result;
  }

  /**
   * Gets strategy's lot size boost (when enabled).
   */
  double SignalOpenBoost(ENUM_ORDER_TYPE _cmd, int _method = 0) {
    bool _result = 1.0;
    if (_method != 0) {
      // if (METHOD(_method, 0)) if (Trade().IsTrend(_cmd)) _result *= 1.1;
      // if (METHOD(_method, 1)) if (Trade().IsPivot(_cmd)) _result *= 1.1;
      // if (METHOD(_method, 2)) if (Trade().IsPeakHours(_cmd)) _result *= 1.1;
      // if (METHOD(_method, 3)) if (Trade().IsRoundNumber(_cmd)) _result *= 1.1;
      // if (METHOD(_method, 4)) if (Trade().IsHedging(_cmd)) _result *= 1.1;
      // if (METHOD(_method, 5)) if (Trade().IsPeakBar(_cmd)) _result *= 1.1;
    }
    return _result;
  }

  /**
   * Check strategy's closing signal.
   */
  bool SignalClose(ENUM_ORDER_TYPE _cmd, int _method = 0, double _level = 0.0) {
    return SignalOpen(Order::NegateOrderType(_cmd), _method, _level);
  }

  /**
   * Gets price limit value for profit take or stop loss.
   */
  double PriceLimit(ENUM_ORDER_TYPE _cmd, ENUM_ORDER_TYPE_VALUE _mode, int _method = 0, double _level = 0.0) {
    Indi_AO *_indi = Data();
    double _trail = _level * Market().GetPipSize();
    int _direction = Order::OrderDirection(_cmd, _mode);
    double _default_value = Market().GetCloseOffer(_cmd) + _trail * _method * _direction;
    double _result = _default_value;
    switch (_method) {
      case 0: {
        int _bar_count = (int) _level * 10;
        _result = _direction > 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest(_bar_count)) : _indi.GetPrice(PRICE_LOW, _indi.GetLowest(_bar_count));
        break;
      }
    }
    return _result;
  }
};
