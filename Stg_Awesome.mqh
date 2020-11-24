/**
 * @file
 * Implements Awesome strategy based on for the Awesome oscillator.
 */

// Includes.
#include <EA31337-classes/Indicators/Indi_AO.mqh>
#include <EA31337-classes/Strategy.mqh>

// User input params.
INPUT float Awesome_LotSize = 0;                 // Lot size
INPUT int Awesome_SignalOpenMethod = 0;          // Signal open method (0-1)
INPUT float Awesome_SignalOpenLevel = 0.0004f;   // Signal open level (>0.0001)
INPUT int Awesome_SignalOpenFilterMethod = 0;    // Signal open filter method (0-1)
INPUT int Awesome_SignalOpenBoostMethod = 0;     // Signal open boost method (0-1)
INPUT float Awesome_SignalCloseLevel = 0.0004f;  // Signal close level (>0.0001)
INPUT int Awesome_SignalCloseMethod = 0;         // Signal close method
INPUT int Awesome_PriceStopMethod = 0;           // Price stop method
INPUT float Awesome_PriceStopLevel = 0;          // Price stop level
INPUT int Awesome_TickFilterMethod = 0;          // Tick filter method
INPUT float Awesome_MaxSpread = 6.0;             // Max spread to trade (pips)
INPUT int Awesome_Shift = 0;                     // Shift (relative to the current bar, 0 - default)

// Structs.

// Defines struct with default user strategy values.
struct Stg_Awesome_Params_Defaults : StgParams {
  Stg_Awesome_Params_Defaults()
      : StgParams(::Awesome_SignalOpenMethod, ::Awesome_SignalOpenFilterMethod, ::Awesome_SignalOpenLevel,
                  ::Awesome_SignalOpenBoostMethod, ::Awesome_SignalCloseMethod, ::Awesome_SignalCloseLevel,
                  ::Awesome_PriceStopMethod, ::Awesome_PriceStopLevel, ::Awesome_TickFilterMethod, ::Awesome_MaxSpread,
                  ::Awesome_Shift) {}
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
    _stg_params.SetStops(_strat, _strat);
    return _strat;
  }

  /**
   * Check strategy's opening signal.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0f, int _shift = 0) {
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
   * Gets price stop value for profit take or stop loss.
   */
  float PriceStop(ENUM_ORDER_TYPE _cmd, ENUM_ORDER_TYPE_VALUE _mode, int _method = 0, float _level = 0.0) {
    Indi_AO *_indi = Data();
    double _trail = _level * Market().GetPipSize();
    int _direction = Order::OrderDirection(_cmd, _mode);
    double _default_value = Market().GetCloseOffer(_cmd) + _trail * _method * _direction;
    double _result = _default_value;
    switch (_method) {
      case 0: {
        int _bar_count = (int)_level * 10;
        _result = _direction > 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest(_bar_count))
                                 : _indi.GetPrice(PRICE_LOW, _indi.GetLowest(_bar_count));
        break;
      }
    }
    return (float)_result;
  }
};
