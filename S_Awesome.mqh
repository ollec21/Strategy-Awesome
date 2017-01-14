//+------------------------------------------------------------------+
//|                 EA31337 - multi-strategy advanced trading robot. |
//|                       Copyright 2016-2017, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

/*
    This file is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

// Properties.
#property strict

/**
 * @file
 * Implementation of Awesome Strategy based on the Awesome oscillator.
 *
 * @docs
 * - https://docs.mql4.com/indicators/iAO
 * - https://www.mql5.com/en/docs/indicators/iAO
 */

// Includes.
#include <EA31337-classes\Strategy.mqh>
#include <EA31337-classes\Strategies.mqh>

// User inputs.
string __Awesome_Parameters__ = "-- Settings for the Awesome oscillator --"; // >>> AWESOME <<<
#ifdef __input__ input #endif double Awesome_SignalLevel = 0.00000000; // Signal level
#ifdef __input__ input #endif string Awesome_SignalLevels = ""; // Signal level
#ifdef __input__ input #endif int Awesome_SignalMethod = 31; // Signal method (0-31)
#ifdef __input__ input #endif string Awesome_SignalMethods = ""; // Signal method (0-31)
//#ifdef __input__ input #endif int Awesome5_SignalMethod = 0; // Signal method for M5 (0-31)
//#ifdef __input__ input #endif int Awesome15_SignalMethod = 31; // Signal method for M15 (0-31)
//#ifdef __input__ input #endif int Awesome30_SignalMethod = 31; // Signal method for M30 (0-31)

class Awesome: public Strategy {

protected:

  int       open_method = EMPTY;    // Open method.
  double    open_level  = 0.0;     // Open level.

public:

  /**
   * Update indicator values.
   */
  bool Update(int tf = EMPTY) {
    // Calculates the Awesome oscillator.
    for (i = 0; i < FINAL_ENUM_INDICATOR_INDEX; i++) {
      awesome[index][i] = iAO(symbol, tf, i);
    }
  }

  /**
   * Check if Awesome indicator is on buy or sell.
   *
   * @param
   *   cmd (int) - type of trade order command
   *   period (int) - period to check for
   *   signal_method (int) - signal method to use by using bitwise AND operation
   *   signal_level (double) - signal level to consider the signal
   */
  bool Signal(int cmd, ENUM_TIMEFRAMES tf = PERIOD_M1, int signal_method = EMPTY, double signal_level = EMPTY) {
    bool result = FALSE; int period = Timeframe::TfToIndex(tf);
    UpdateIndicator(S_AWESOME, tf);
    if (signal_method == EMPTY) signal_method = GetStrategySignalMethod(S_AWESOME, tf, 0);
    if (signal_level  == EMPTY) signal_level  = GetStrategySignalLevel(S_AWESOME, tf, 0.0);
    switch (cmd) {
      /*
        //7. Awesome Oscillator
        //Buy: 1. Signal "saucer" (3 positive columns, medium column is smaller than 2 others); 2. Changing from negative values to positive.
        //Sell: 1. Signal "saucer" (3 negative columns, medium column is larger than 2 others); 2. Changing from positive values to negative.
        if ((iAO(NULL,piao,2)>0&&iAO(NULL,piao,1)>0&&iAO(NULL,piao,0)>0&&iAO(NULL,piao,1)<iAO(NULL,piao,2)&&iAO(NULL,piao,1)<iAO(NULL,piao,0))||(iAO(NULL,piao,1)<0&&iAO(NULL,piao,0)>0))
        {f7=1;}
        if ((iAO(NULL,piao,2)<0&&iAO(NULL,piao,1)<0&&iAO(NULL,piao,0)<0&&iAO(NULL,piao,1)>iAO(NULL,piao,2)&&iAO(NULL,piao,1)>iAO(NULL,piao,0))||(iAO(NULL,piao,1)>0&&iAO(NULL,piao,0)<0))
        {f7=-1;}
      */
      case OP_BUY:
        /*
          bool result = Awesome[period][CURR][LOWER] != 0.0 || Awesome[period][PREV][LOWER] != 0.0 || Awesome[period][FAR][LOWER] != 0.0;
          if ((signal_method &   1) != 0) result &= Open[CURR] > Close[CURR];
          if ((signal_method &   2) != 0) result &= !Awesome_On_Sell(tf);
          if ((signal_method &   4) != 0) result &= Awesome_On_Buy(fmin(period + 1, M30));
          if ((signal_method &   8) != 0) result &= Awesome_On_Buy(M30);
          if ((signal_method &  16) != 0) result &= Awesome[period][FAR][LOWER] != 0.0;
          if ((signal_method &  32) != 0) result &= !Awesome_On_Sell(M30);
          */
      break;
      case OP_SELL:
        /*
          bool result = Awesome[period][CURR][UPPER] != 0.0 || Awesome[period][PREV][UPPER] != 0.0 || Awesome[period][FAR][UPPER] != 0.0;
          if ((signal_method &   1) != 0) result &= Open[CURR] < Close[CURR];
          if ((signal_method &   2) != 0) result &= !Awesome_On_Buy(tf);
          if ((signal_method &   4) != 0) result &= Awesome_On_Sell(fmin(period + 1, M30));
          if ((signal_method &   8) != 0) result &= Awesome_On_Sell(M30);
          if ((signal_method &  16) != 0) result &= Awesome[period][FAR][UPPER] != 0.0;
          if ((signal_method &  32) != 0) result &= !Awesome_On_Buy(M30);
          */
      break;
    }
    result &= signal_method <= 0 || Convert::ValueToOp(curr_trend) == cmd;
    return result;
  }
};
