//+------------------------------------------------------------------+
//|                                                  CorrectLots.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Возвращает корректный лот                                        |
//+------------------------------------------------------------------+
double CorrectLots(const double lots, const bool to_min_correct = true)
{
  double min = m_symbol_info.LotsMin();
  double max = m_symbol_info.LotsMax();
  double step = m_symbol_info.LotsStep();
  return (to_min_correct ? VolumeRoundToSmaller(lots, min, max, step) : VolumeRoundToCorrect(lots, min, max, step));
}