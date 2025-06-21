//+------------------------------------------------------------------+
//|                                             MyFirstStrategy.mq5  |
//|                                   © Forex Assistant, Alan Norberg|
//|                                      Версия 1.0: Ваша первая идея |
//+------------------------------------------------------------------+
#property version "1.0"

//--- Входные параметры
input int    ImpulseBars          = 3;      // Сколько свечей в импульсе
input double PullbackBodyRatio    = 0.33;   // Макс. размер откатной свечи (1/3 от импульса)
input double TakeProfitRatio      = 0.33;   // Уровень тейк-профита (1/3 от импульса)
input double StopLossPips         = 30;     // Фиксированный стоп-лосс в пипсах
input double LotSize              = 0.01;   // Размер лота

//+------------------------------------------------------------------+
//| Главная функция, которая выполняется на каждом новом баре        |
//+------------------------------------------------------------------+
void OnTick()
{
    //--- Проверка на новый бар ---
    static datetime prev_time = 0;
    datetime current_time = iTime(_Symbol, _Period, 0);
    if(prev_time == current_time) return;
    prev_time = current_time;

    //--- Если уже есть открытая позиция, ничего не делаем ---
    if(PositionSelect(_Symbol)) return;

    //--- Получаем последние N+2 свечи для анализа ---
    int bars_to_copy = ImpulseBars + 2;
    MqlRates rates[];
    if(CopyRates(_Symbol, _Period, 0, bars_to_copy, rates) < bars_to_copy) return;
    ArraySetAsSeries(rates, true);

    // --- Анализ на сигнал ПОКУПКИ ---
    // 1. Ищем импульс ВНИЗ (красный прямоугольник)
    bool bearish_impulse = true;
    double impulse_high = 0;
    double impulse_low = 999999;
    for(int i = 2; i < 2 + ImpulseBars; i++)
    {
        if(rates[i].close >= rates[i].open) bearish_impulse = false; // Если хоть одна свеча не медвежья
        if(rates[i].high > impulse_high) impulse_high = rates[i].high;
        if(rates[i].low < impulse_low) impulse_low = rates[i].low;
    }
    
    // 2. Если был импульс вниз, ищем маленькую откатную свечу ВВЕРХ (голубой прямоугольник)
    if(bearish_impulse)
    {
        double pullback_candle_open = rates[1].open;
        double pullback_candle_close = rates[1].close;
        double impulse_height = impulse_high - impulse_low;
        
        // Проверяем, что свеча бычья и ее тело меньше 1/3 импульса
        if(pullback_candle_close > pullback_candle_open && (pullback_candle_close - pullback_candle_open) < impulse_height * PullbackBodyRatio)
        {
            Print("Найден сетап на ПОКУПКУ. Импульс вниз, откат вверх.");
            // 3. Открываем сделку
            MqlTradeRequest request; MqlTradeResult result; ZeroMemory(request); ZeroMemory(result);
            double price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
            
            request.action = TRADE_ACTION_DEAL; request.symbol = _Symbol; request.volume = LotSize;
            request.type = ORDER_TYPE_BUY; request.price = price;
            request.sl = price - (StopLossPips * 10 * point);
            request.tp = pullback_candle_close + (impulse_height * TakeProfitRatio); // 4. Устанавливаем тейк-профит
            request.magic = 11111; request.comment = "Buy by MyFirstStrategy";
            if(!OrderSend(request, result))
        {
        Print("Ошибка отправки ордера BUY! Код: ", result.retcode);
}
else
{
    Print("Ордер BUY (#%d) успешно отправлен.", result.order);
}
        }
    }
    
    // --- Анализ на сигнал ПРОДАЖИ (зеркальная логика) ---
    // 1. Ищем импульс ВВЕРХ
    bool bullish_impulse = true;
    impulse_high = 0;
    impulse_low = 999999;
    for(int i = 2; i < 2 + ImpulseBars; i++)
    {
        if(rates[i].close <= rates[i].open) bullish_impulse = false;
        if(rates[i].high > impulse_high) impulse_high = rates[i].high;
        if(rates[i].low < impulse_low) impulse_low = rates[i].low;
    }
    
    // 2. Если был импульс вверх, ищем маленькую откатную свечу ВНИЗ
    if(bullish_impulse)
    {
        double pullback_candle_open = rates[1].open;
        double pullback_candle_close = rates[1].close;
        double impulse_height = impulse_high - impulse_low;

        if(pullback_candle_close < pullback_candle_open && (pullback_candle_open - pullback_candle_close) < impulse_height * PullbackBodyRatio)
        {
            Print("Найден сетап на ПРОДАЖУ. Импульс вверх, откат вниз.");
            // 3. Открываем сделку
            MqlTradeRequest request; MqlTradeResult result; ZeroMemory(request); ZeroMemory(result);
            double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

            request.action = TRADE_ACTION_DEAL; request.symbol = _Symbol; request.volume = LotSize;
            request.type = ORDER_TYPE_SELL; request.price = price;
            request.sl = price + (StopLossPips * 10 * point);
            request.tp = pullback_candle_close - (impulse_height * TakeProfitRatio); // 4. Устанавливаем тейк-профит
            request.magic = 22222; request.comment = "Sell by MyFirstStrategy";
            if(!OrderSend(request, result))
{
    Print("Ошибка отправки ордера SELL! Код: ", result.retcode);
}
else
{
    Print("Ордер SELL (#%d) успешно отправлен.", result.order);
}
        }
    }
}
