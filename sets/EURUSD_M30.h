//+------------------------------------------------------------------+
//|                  EA31337 - multi-strategy advanced trading robot |
//|                       Copyright 2016-2020, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

// Defines strategy's parameter values for the given pair symbol and timeframe.
struct Stg_Awesome_EURUSD_M30_Params : Stg_Awesome_Params {
  Stg_Awesome_EURUSD_M30_Params() {
    symbol = "EURUSD";
    tf = PERIOD_M30;
    Awesome_Shift = 0;
    Awesome_TrailingStopMethod = 0;
    Awesome_TrailingProfitMethod = 0;
    Awesome_SignalOpenLevel = 0;
    Awesome_SignalBaseMethod = 0;
    Awesome_SignalOpenMethod1 = 0;
    Awesome_SignalOpenMethod2 = 0;
    Awesome_SignalCloseLevel = 0;
    Awesome_SignalCloseMethod1 = 0;
    Awesome_SignalCloseMethod2 = 0;
    Awesome_MaxSpread = 0;
  }
};
