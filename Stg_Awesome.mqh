/**
 * @file
 * Implements Awesome strategy based on for the Awesome oscillator.
 */

// User input params.
INPUT string __Awesome_Parameters__ = "-- Awesome strategy params --";  // >>> Awesome <<<
INPUT float Awesome_LotSize = 0;                                        // Lot size
INPUT int Awesome_SignalOpenMethod = 0;                                 // Signal open method (-7-7)
INPUT float Awesome_SignalOpenLevel = 0.0f;                             // Signal open level (>0.0001)
INPUT int Awesome_SignalOpenFilterMethod = 1;                           // Signal open filter method (0-1)
INPUT int Awesome_SignalOpenBoostMethod = 0;                            // Signal open boost method (0-1)
INPUT float Awesome_SignalCloseLevel = 0.0f;                            // Signal close level (>0.0001)
INPUT int Awesome_SignalCloseMethod = 0;                                // Signal close method (-7-7)
INPUT int Awesome_PriceStopMethod = 0;                                  // Price stop method
INPUT float Awesome_PriceStopLevel = 0;                                 // Price stop level
INPUT int Awesome_TickFilterMethod = 1;                                 // Tick filter method
INPUT float Awesome_MaxSpread = 4.0;                                    // Max spread to trade (pips)
INPUT int Awesome_Shift = 0;             // Shift (relative to the current bar, 0 - default)
INPUT int Awesome_OrderCloseTime = -20;  // Order close time in mins (>0) or bars (<0)
INPUT string __Awesome_Indi_Awesome_Parameters__ =
    "-- Awesome strategy: Awesome indicator params --";  // >>> Awesome strategy: Awesome indicator <<<
INPUT int Awesome_Indi_Awesome_Shift = 0;                // Shift

// Structs.

// Defines struct with default user indicator values.
struct Indi_Awesome_Params_Defaults : AOParams {
  Indi_Awesome_Params_Defaults() : AOParams(::Awesome_Indi_Awesome_Shift) {}
} indi_awesome_defaults;

// Defines struct with default user strategy values.
struct Stg_Awesome_Params_Defaults : StgParams {
  Stg_Awesome_Params_Defaults()
      : StgParams(::Awesome_SignalOpenMethod, ::Awesome_SignalOpenFilterMethod, ::Awesome_SignalOpenLevel,
                  ::Awesome_SignalOpenBoostMethod, ::Awesome_SignalCloseMethod, ::Awesome_SignalCloseLevel,
                  ::Awesome_PriceStopMethod, ::Awesome_PriceStopLevel, ::Awesome_TickFilterMethod, ::Awesome_MaxSpread,
                  ::Awesome_Shift, ::Awesome_OrderCloseTime) {}
} stg_awesome_defaults;

// Struct to define strategy parameters to override.
struct Stg_Awesome_Params : StgParams {
  StgParams sparams;

  // Struct constructors.
  Stg_Awesome_Params(StgParams &_sparams) : sparams(stg_awesome_defaults) { sparams = _sparams; }
};

// Loads pair specific param values.
#include "config/EURUSD_H1.h"
#include "config/EURUSD_H4.h"
#include "config/EURUSD_H8.h"
#include "config/EURUSD_M1.h"
#include "config/EURUSD_M15.h"
#include "config/EURUSD_M30.h"
#include "config/EURUSD_M5.h"

class Stg_Awesome : public Strategy {
 public:
  Stg_Awesome(StgParams &_params, string _name) : Strategy(_params, _name) {}

  static Stg_Awesome *Init(ENUM_TIMEFRAMES _tf = NULL, long _magic_no = NULL, ENUM_LOG_LEVEL _log_level = V_INFO) {
    // Initialize strategy initial values.
    StgParams _stg_params(stg_awesome_defaults);
    if (!Terminal::IsOptimization()) {
      SetParamsByTf<StgParams>(_stg_params, _tf, stg_awesome_m1, stg_awesome_m5, stg_awesome_m15, stg_awesome_m30,
                               stg_awesome_h1, stg_awesome_h4, stg_awesome_h8);
    }
    // Initialize indicator.
    AOParams _indi_params(_tf);
    _stg_params.SetIndicator(new Indi_AO(_indi_params));
    // Initialize strategy parameters.
    _stg_params.GetLog().SetLevel(_log_level);
    _stg_params.SetMagicNo(_magic_no);
    _stg_params.SetTf(_tf, _Symbol);
    // Initialize strategy instance.
    Strategy *_strat = new Stg_Awesome(_stg_params, "Awesome");
    return _strat;
  }

  /**
   * Check strategy's opening signal.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0f, int _shift = 0) {
    Indi_AO *_indi = Data();
    bool _is_valid = _indi[CURR].IsValid();
    bool _result = _is_valid;
    if (_is_valid) {
      switch (_cmd) {
        case ORDER_TYPE_BUY:
          // Signal "saucer": 3 positive columns, medium column is smaller than 2 others.
          _result = _indi[CURR][0] < 0 && _indi.IsIncreasing(3);
          _result &= _indi.IsIncByPct(_level, 0, 0, 2);
          if (_result && _method != 0) {
            if (METHOD(_method, 0)) _result &= _indi.IsIncreasing(2, 0, 3);
            if (METHOD(_method, 1)) _result &= _indi.IsIncreasing(2, 0, 5);
            // Signal: Changing from negative values to positive.
            if (METHOD(_method, 2)) _result &= _indi[PPREV][0] > 0;
          }
          break;
        case ORDER_TYPE_SELL:
          // Signal "saucer": 3 negative columns, medium column is larger than 2 others.
          _result = _indi[CURR][0] > 0 && _indi.IsDecreasing(3);
          _result &= _indi.IsDecByPct(-_level, 0, 0, 2);
          if (_result && _method != 0) {
            if (METHOD(_method, 0)) _result &= _indi.IsDecreasing(2, 0, 3);
            if (METHOD(_method, 1)) _result &= _indi.IsDecreasing(2, 0, 5);
            // Signal: Changing from positive values to negative.
            if (METHOD(_method, 2)) _result &= _indi[PPREV][0] < 0;
          }
          break;
      }
    }
    return _result;
  }

  /**
   * Gets price stop value for profit take or stop loss.
   */
  float PriceStop(ENUM_ORDER_TYPE _cmd, ENUM_ORDER_TYPE_VALUE _mode, int _method = 0, float _level = 0.0) {
    Chart *_chart = sparams.GetChart();
    Indi_AO *_indi = Data();
    bool _is_valid = _indi[CURR].IsValid();
    double _trail = _level * Market().GetPipSize();
    int _bar_count = (int)_level;
    int _bar_lowest = _indi.GetLowest<double>(_bar_count), _bar_highest = _indi.GetHighest<double>(_bar_count);
    int _direction = Order::OrderDirection(_cmd, _mode);
    double _change_pc = Math::ChangeInPct(_indi[PREV][0], _indi[CURR][0]);
    double _default_value = Market().GetCloseOffer(_cmd) + _trail * _method * _direction;
    double _price_offer = _chart.GetOpenOffer(_cmd);
    double _result = _default_value;
    ENUM_APPLIED_PRICE _ap = _direction > 0 ? PRICE_HIGH : PRICE_LOW;
    switch (_method) {
      case 1:
        _result = _direction > 0 ? _indi.GetPrice(_ap, _bar_highest) : _indi.GetPrice(_ap, _bar_lowest);
        break;
      case 2:
        _result = _direction > 0 ? fmax(_indi.GetPrice(_ap, _bar_lowest), _indi.GetPrice(_ap, _bar_highest))
                                 : fmin(_indi.GetPrice(_ap, _bar_lowest), _indi.GetPrice(_ap, _bar_highest));
        break;
      case 3:
        _result = Math::ChangeByPct(_price_offer, (float)_change_pc / _level);
        break;
    }
    _result = +_trail;
    return (float)_result;
  }
};
