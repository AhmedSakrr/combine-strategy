
// This source code is subject to the terms of the Mozilla Public License 2.0 at https://mozilla.org/MPL/2.0/
// @ mrhili

//@version=5


indicator(title='combine stragegies 2', shorttitle='CMB2', overlay=true, format=format.inherit , max_bars_back=500)


activate_knn_strategy = input(title='Activate KNN STRATEGY ?', defval=false)

//indicator('Machine Learning: kNN-based Strategy (s2)', overlay=true, precision=4, max_labels_count=200)

// kNN-based Strategy (FX and Crypto)
// Description: 
// This strategy uses a classic machine learning algorithm - k Nearest Neighbours (kNN) - 
// to let you find a prediction for the next (tomorrow's, next month's, etc.) market move. 
// Being an unsupervised machine learning algorithm, kNN is one of the most simple learning algorithms. 

// To do a prediction of the next market move, the kNN algorithm uses the historic data, 
// collected in 3 arrays - feature1_knn, feature2_knn and directions_knn, - and finds the k-nearest 
// neighbours of the current indicator(s) values. 

// The two dimensional kNN algorithm just has a look on what has happened in the past when 
// the two indicators had a similar level. It then looks at the k nearest neighbours, 
// sees their state and thus classifies the current point.

// The kNN algorithm offers a framework to test all kinds of indicators easily to see if they 
// have got any *predictive value*. One can easily add cog, wpr and others.
// Note: TradingViewss playback feature helps to see this strategy in action.
// Warning: signal_knns ARE repainting.

// Style tags: Trend Following, Trend Analysis
// Asset class: Equities, Futures, ETFs, Currencies and Commodities
// Dataset: FX Minutes/Hours+++/Days

//-------------------- Inputs

ind_knn = input.string('All', 'Indicator', options=['RSI', 'ROC', 'CCI', 'All'])
fast_knn = input.int(14, 'Fast Period', minval=1)
slow_knn = input.int(28, 'slow_knn Period', minval=2)
fltr_knn = input(false, 'To Filter Out Signals By Volatility?')

startYear_knn = input.int(2000, 'Training Start Year', minval=2000)
startMonth_knn = input.int(1, 'Training Start Month', minval=1, maxval=12)
startDay_knn = input.int(1, 'Training Start Day', minval=1, maxval=31)
stopYear_knn = input.int(2021, 'Training Stop Year', minval=2000)
stopMonth_knn = input.int(12, 'Training Stop Month', minval=1, maxval=12)
stopDay_knn = input.int(31, 'Training Stop Day', minval=1, maxval=31)

//-------------------- Global Variables

var BUY_knn = 1
var SELL_knn = -1
var HOLD_knn = 0

var k_knn = math.floor(math.sqrt(252))  // k Value for kNN

//-------------------- Custom Functions

cAqua(g) =>
    g > 9 ? #0080FFff : g > 8 ? #0080FFe5 : g > 7 ? #0080FFcc : g > 6 ? #0080FFb2 : g > 5 ? #0080FF99 : g > 4 ? #0080FF7f : g > 3 ? #0080FF66 : g > 2 ? #0080FF4c : g > 1 ? #0080FF33 : #00C0FF19
cPink(g) =>
    g > 9 ? #FF0080ff : g > 8 ? #FF0080e5 : g > 7 ? #FF0080cc : g > 6 ? #FF0080b2 : g > 5 ? #FF008099 : g > 4 ? #FF00807f : g > 3 ? #FF008066 : g > 2 ? #FF00804c : g > 1 ? #FF008033 : #FF008019

//-------------------- Logic

periodStart_knn = timestamp(startYear_knn, startMonth_knn, startDay_knn, 0, 0)
periodStop_knn = timestamp(stopYear_knn, stopMonth_knn, stopDay_knn, 0, 0)

// 3 pairs of predictor indicators, long and short each
rs_knn = ta.rsi(close, slow_knn)
rf_knn = ta.rsi(close, fast_knn)
cs_knn = ta.cci(close, slow_knn)
cf_knn = ta.cci(close, fast_knn)
os_knn = ta.roc(close, slow_knn)
of_knn = ta.roc(close, fast_knn)
// TOADD or TOTRYOUT:
//    cmo(close, slow_knn), cmo(close, fast_knn)
//    mfi(close, slow_knn), mfi(close, fast_knn)
//    mom(close, slow_knn), mom(close, fast_knn)
f1_knn = ind_knn == 'RSI' ? rs_knn : ind_knn == 'ROC' ? os_knn : ind_knn == 'CCI' ? cs_knn : math.avg(rs_knn, os_knn, cs_knn)
f2_knn = ind_knn == 'RSI' ? rf_knn : ind_knn == 'ROC' ? of_knn : ind_knn == 'CCI' ? cf_knn : math.avg(rf_knn, of_knn, cf_knn)

// Classification data, what happens on the next bar
class1_knn = close[1] < close[0] ? SELL_knn : close[1] > close[0] ? BUY_knn : HOLD_knn

// Training data, normalized to the range of [0,...,100]
var feature1_knn = array.new_float(0)  // [0,...,100]
var feature2_knn = array.new_float(0)  //    ...
var directions_knn = array.new_int(0)  // [-1; +1]

// Result data
var predictions_knn = array.new_int(0)
var prediction_knn = 0.

var startLongTrade_knn = false
var startShortTrade_knn = false
var endLongTrade_knn = false
var endShortTrade_knn = false

var signal_knn = HOLD_knn

// Use particular training period
if time >= periodStart_knn and time <= periodStop_knn
    // Store everything in arrays. Features represent a square 100 x 100 matrix,
    // whose row-colum intersections represent class labels, showing historic directions_knn
    array.push(feature1_knn, f1_knn)
    array.push(feature2_knn, f2_knn)
    array.push(directions_knn, class1_knn)

// Ucomment the followng statement (if barstate.islast) and tab everything below
// between BOBlock and EOBlock marks to see just the recent several signals gradually 
// showing up, rather than all the preceding signals

//if barstate.islast   

//==BOBlock	

// Core logic of the algorithm
size_knn = array.size(directions_knn)
maxdist_knn = -999.
// Loop through the training arrays, getting distances and corresponding directions_knn.
for i_knn = 0 to size_knn - 1 by 1
    // Calculate the euclidean distance of current point to all historic points,
    // here the metric used might as well be a manhattan distance or any other.
    d = math.sqrt(math.pow(f1_knn - array.get(feature1_knn, i_knn), 2) + math.pow(f2_knn - array.get(feature2_knn, i_knn), 2))

    if d > maxdist_knn
        maxdist_knn := d
        if array.size(predictions_knn) >= k_knn
            array.shift(predictions_knn)
        array.push(predictions_knn, array.get(directions_knn, i_knn))

//==EOBlock	

// Note: in this setup theres no need for distances array (i.e. array.push(distances, d)),
//       but the drawback is that a sudden max value may shadow all the subsequent values.
// One of the ways to bypass this is to:
// 1) store d in distances array,
// 2) calculate newdirs = bubbleSort(distances, directions_knn), and then 
// 3) take a slice with array.slice(newdirs) from the end

// Get the overall prediction of k nearest neighbours
prediction_knn := array.sum(predictions_knn)

// Now that we got a prediction for the next market move, we need to make use of this prediction and 
// trade it. The returns then will show if everything works as predicted.
// Over here is a simple long/short interpretation of the prediction, 
// but of course one could also use the quality of the prediction (+5 or +1) in some sort of way,
// ex. for position sizing.

signal_knn := prediction_knn > 0 ? BUY_knn : prediction_knn < 0 ? SELL_knn : nz(signal_knn[1])  // HOLD_knn

changed_knn = ta.change(signal_knn)

filter_knn = fltr_knn ? ta.atr(13) > ta.atr(40) : true
startLongTrade_knn := changed_knn and signal_knn == BUY_knn and filter_knn  // filter out by high volatility, 
startShortTrade_knn := changed_knn and signal_knn == SELL_knn and filter_knn  // or ex. atr(1) > atr(10)...
endLongTrade_knn := changed_knn and signal_knn == SELL_knn  //TOADD: stop by trade duration
endShortTrade_knn := changed_knn and signal_knn == BUY_knn

//-------------------- Rendering

plotshape(activate_knn_strategy and startLongTrade_knn ? low : na, location=location.belowbar, style=shape.labelup, color=cAqua(prediction_knn * 5), size=size.small, title='Buy')  // color intensity correction
plotshape(activate_knn_strategy and startShortTrade_knn ? high : na, location=location.abovebar, style=shape.labeldown, color=cPink(-prediction_knn * 5), size=size.small, title='Sell')
plot(activate_knn_strategy and endLongTrade_knn ? high : na, style=plot.style_cross, color=cAqua(6), linewidth=3, title='StopBuy')
plot(activate_knn_strategy and endShortTrade_knn ? low : na, style=plot.style_cross, color=cPink(6), linewidth=3, title='StopSell')

//-------------------- Alerting

if changed_knn and signal_knn == BUY_knn
    alert('Buy Alert', alert.freq_once_per_bar)  // alert.freq_once_per_bar_close
if changed_knn and signal_knn == SELL_knn
    alert('Sell Alert', alert.freq_once_per_bar)

alertcondition(startLongTrade_knn, title='Buy', message='Go long!')
alertcondition(startShortTrade_knn, title='Sell', message='Go short!')
//alertcondition(startLongTrade_knn or startShortTrade_knn, title='Alert', message='Deal Time!')

//-------------------- Backtesting (TODO)

show_cumtr_knn = input(false, 'Show Trade Return?')
lot_size_knn = input.float(100.0, 'Lot Size', options=[0.1, 0.2, 0.3, 0.5, 1, 2, 3, 5, 10, 20, 30, 50, 100, 1000, 2000, 3000, 5000, 10000])

var start_lt_knn = 0.
var long_trades_knn = 0.
var start_st_knn = 0.
var short_trades_knn = 0.

if startLongTrade_knn
    start_lt_knn := ohlc4
    start_lt_knn
if endLongTrade_knn
    long_trades_knn := (open - start_lt_knn) * lot_size_knn
    long_trades_knn
if startShortTrade_knn
    start_st_knn := ohlc4
    start_st_knn
if endShortTrade_knn
    short_trades_knn := (start_st_knn - open) * lot_size_knn
    short_trades_knn

cumreturn_knn = ta.cum(long_trades_knn) + ta.cum(short_trades_knn)

var label lbl_knn = na
if show_cumtr_knn  //and barstate.islast  
    lbl_knn := label.new(bar_index, close, 'CumReturn: ' + str.tostring(cumreturn_knn, '#.#'), xloc.bar_index, yloc.price, color.new(color.blue, 100), label.style_label_left, color.black, size.small, text.align_left)
    label.delete(lbl_knn[1])





//******************************************************
//START VWMA with kNN Machine Learning: MFI/ADX by lastguru

activate_vwma_knn_strategy = input(title='Activate VWMA KNN STRATEGY ?', defval=false)

/////////
// kNN //
/////////

// Define storage arrays for: parameter 1, parameter 2, price, result (up = 1; down = -1)
var knn1_vwmaknn = array.new_float(1, 0)
var knn2_vwmaknn = array.new_float(1, 0)
var knnp_vwmaknn = array.new_float(1, 0)
var knnr_vwmaknn = array.new_float(1, 0)

// Store the previous trade; buffer the current one until results are in
_knnStore(p1, p2, src) =>
    var prevp1_vwmaknn = 0.0
    var prevp2_vwmaknn = 0.0
    var prevsrc_vwmaknn = 0.0

    array.push(knn1_vwmaknn, prevp1_vwmaknn)
    array.push(knn2_vwmaknn, prevp2_vwmaknn)
    array.push(knnp_vwmaknn, prevsrc_vwmaknn)
    array.push(knnr_vwmaknn, src >= prevsrc_vwmaknn ? 1 : -1)

    prevp1_vwmaknn := p1
    prevp2_vwmaknn := p2
    prevsrc_vwmaknn := src
    prevsrc_vwmaknn

// Get neighbours by getting k smallest distances from the distance array, and then getting all results with these distances
_knnGet_vwmaknn(arr1, arr2, k) =>
    sarr = array.copy(arr1)
    array.sort(sarr)
    ss = array.slice(sarr, 0, math.min(k, array.size(sarr)))
    m = array.max(ss)
    out = array.new_float(0)
    for i = 0 to array.size(arr1) - 1 by 1
        if array.get(arr1, i) <= m
            array.push(out, array.get(arr2, i))
    out

// Create a distance array from the two given parameters
_knnDistance_vwmaknn(p1, p2) =>
    dist = array.new_float(0)
    n = array.size(knn1_vwmaknn) - 1
    for i = 0 to n by 1
        d = math.sqrt(math.pow(p1 - array.get(knn1_vwmaknn, i), 2) + math.pow(p2 - array.get(knn2_vwmaknn, i), 2))
        array.push(dist, d)
    dist

// Make a prediction, finding k nearest neighbours
_knn_vwmaknn(p1, p2, k) =>
    slice = _knnGet_vwmaknn(_knnDistance_vwmaknn(p1, p2), array.copy(knnr_vwmaknn), k)
    knn = array.sum(slice)
    knn

////////////
// Inputs //
////////////

SRC_vwmaknn = input(title='Source', defval=close)
FAST_vwmaknn = input(title='Fast Length', defval=13)
SLOW_vwmaknn = input(title='Slow Length', defval=19)
APPLY_vwmaknn = input(title='Apply kNN filter', defval=true)
FILTER_vwmaknn = input(title='Filter Length', defval=13)
SMOOTH_vwmaknn = input(title='Filter Smoothing', defval=6)
// When DIST is 0, KNN_vwmaknn default was 23
KNN_vwmaknn = input(title='kNN nearest neighbors (k)', defval=45)
DIST_vwmaknn = input(title='kNN minimum difference', defval=2)
BACKGROUND_vwmaknn = input(title='Draw background', defval=false)

////////
// MA //
////////
fastMA_vwmaknn = ta.vwma(SRC_vwmaknn, FAST_vwmaknn)
slowMA_vwmaknn = ta.vwma(SRC_vwmaknn, SLOW_vwmaknn)

/////////
// DMI //
/////////

// Wilders Smoothing (Running Moving Average)
_rma_vwmaknn(src, length) =>
    out = 0.0
    out := ((length - 1) * nz(out[1]) + src) / length
    out

// DMI (Directional Movement Index)
_dmi_vwmaknn(len, smooth) =>
    up = ta.change(high)
    down = -ta.change(low)
    plusDM = na(up) ? na : up > down and up > 0 ? up : 0
    minusDM = na(down) ? na : down > up and down > 0 ? down : 0
    trur = _rma_vwmaknn(ta.tr, len)
    plus = fixnan(100 * _rma_vwmaknn(plusDM, len) / trur)
    minus = fixnan(100 * _rma_vwmaknn(minusDM, len) / trur)
    sum = plus + minus
    adx = 100 * _rma_vwmaknn(math.abs(plus - minus) / (sum == 0 ? 1 : sum), smooth)
    [plus, minus, adx]

[diplus, diminus, adx] = _dmi_vwmaknn(FILTER_vwmaknn, SMOOTH_vwmaknn)

/////////
// MFI //
/////////

// common RSI function
_rsi_vwmaknn(upper, lower) =>
    if lower == 0
        100
    if upper == 0
        0
    100.0 - 100.0 / (1.0 + upper / lower)

mfiUp_vwmaknn = math.sum(volume * (ta.change(ohlc4) <= 0 ? 0 : ohlc4), FILTER_vwmaknn)
mfiDown_vwmaknn = math.sum(volume * (ta.change(ohlc4) >= 0 ? 0 : ohlc4), FILTER_vwmaknn)
mfi_vwmaknn = _rsi_vwmaknn(mfiUp_vwmaknn, mfiDown_vwmaknn)

////////////
// Filter //
////////////

longCondition_vwmaknn = ta.crossover(fastMA_vwmaknn, slowMA_vwmaknn)
shortCondition_vwmaknn = ta.crossunder(fastMA_vwmaknn, slowMA_vwmaknn)

if longCondition_vwmaknn or shortCondition_vwmaknn
    _knnStore(adx, mfi_vwmaknn, SRC_vwmaknn)
filter_vwmaknn = _knn_vwmaknn(adx, mfi_vwmaknn, KNN_vwmaknn)

/////////////
// Actions //
/////////////

bgcolor(BACKGROUND_vwmaknn ? filter_vwmaknn >= 0 ? color.green : color.red : na, transp=90)
plot(activate_vwma_knn_strategy? fastMA_vwmaknn : na, color=color.new(color.red, 0))
plot(activate_vwma_knn_strategy? slowMA_vwmaknn:na , color=color.new(color.green, 0))

long_vwmaknn=false
short_vwmaknn=false

if longCondition_vwmaknn and (not APPLY_vwmaknn or filter_vwmaknn >= DIST_vwmaknn)

    long_vwmaknn:=true
else
    long_vwmaknn:=false

if shortCondition_vwmaknn and (not APPLY_vwmaknn or filter_vwmaknn <= -DIST_vwmaknn)

    short_vwmaknn:=true
else
    short_vwmaknn:=false

//if longCondition_vwmaknn and (not APPLY_vwmaknn or filter_vwmaknn >= DIST_vwmaknn)
//    strategy.entry('Long', strategy.long)
//if shortCondition_vwmaknn and (not APPLY_vwmaknn or filter_vwmaknn <= -DIST_vwmaknn)
//    strategy.entry('Short', strategy.short)

//plot(long_vwmaknn ? low : na, style=plot.style_cross, color=color.new(color.green, 0), linewidth=3, title='long')
//plotshape(long_vwmaknn ? low : na, title='Long STOP', location=location.absolute, style=shape.circle, size=size.tiny, color=color.new(color.green, 0), transp=0)
plotshape(activate_vwma_knn_strategy and long_vwmaknn ? low : na, title='Buy Label', text='Buy', location=location.absolute, style=shape.labelup, size=size.tiny, color=color.new(color.green, 0), textcolor=color.new(color.white, 0), transp=0)


//plotshape(short_vwmaknn ? high : na, title='SHORT STOP', location=location.absolute, style=shape.circle, size=size.tiny, color=color.new(color.green, 0), transp=0)
plotshape(activate_vwma_knn_strategy and short_vwmaknn ? high : na, title='SELL Label', text='SELL', location=location.absolute, style=shape.labeldown, size=size.tiny, color=color.new(color.red, 0), textcolor=color.new(color.white, 0), transp=0)




//END VWMA with kNN Machine Learning: MFI/ADX by lastguru
//******************************************************


//START LINEAR REGRESSION CHANNEL


src_lrgc = input(defval=close, title='Source')
len_lrgc = input.int(defval=100, title='Length', minval=10)
devlen_lrgc = input.float(defval=2., title='Deviation', minval=0.1, step=0.1)
extendit_lrgc = input(defval=true, title='Extend Lines')
showfibo_lrgc = input(defval=false, title='Show Fibonacci Levels')
showbroken_lrgc = input.bool(defval=true, title='Show Broken Channel', inline='brk')
brokencol_lrgc = input.color(defval=color.blue, title='', inline='brk')
upcol_lrgc = input.color(defval=color.lime, title='Up/Down Trend Colors', inline='trcols')
dncol_lrgc = input.color(defval=color.red, title='', inline='trcols')
widt_lrgc = input(defval=2, title='Line Width')


var fibo_ratios_lrgc = array.new_float(0)
var colors_lrgc = array.new_color(2)
if barstate.isfirst
    array.unshift(colors_lrgc, upcol_lrgc)
    array.unshift(colors_lrgc, dncol_lrgc)
    array.push(fibo_ratios_lrgc, 0.236)
    array.push(fibo_ratios_lrgc, 0.382)
    array.push(fibo_ratios_lrgc, 0.618)
    array.push(fibo_ratios_lrgc, 0.786)


get_channel_lrgc(src, len) =>
    mid = math.sum(src, len) / len
    slope = ta.linreg(src, len, 0) - ta.linreg(src, len, 1)
    intercept = mid - slope * math.floor(len / 2) + (1 - len % 2) / 2 * slope
    endy = intercept + slope * (len - 1)
    dev = 0.0
    for x = 0 to len - 1 by 1
        dev := dev + math.pow(src[x] - (slope * (len - x) + intercept), 2)
        dev
    dev := math.sqrt(dev / len)
    [intercept, endy, dev, slope]

[y1_, y2_, dev, slope] = get_channel_lrgc(src_lrgc, len_lrgc)

outofchannel_lrgc = slope > 0 and close < y2_ - dev * devlen_lrgc ? 0 : slope < 0 and close > y2_ + dev * devlen_lrgc ? 2 : -1

var reglines_lrgc = array.new_line(3)
var fibolines_lrgc = array.new_line(4)
for x = 0 to 2 by 1
    if not showbroken_lrgc or outofchannel_lrgc != x or nz(outofchannel_lrgc[1], -1) != -1
        line.delete(array.get(reglines_lrgc, x))
    else
        line.set_color(array.get(reglines_lrgc, x), color=brokencol_lrgc)
        line.set_width(array.get(reglines_lrgc, x), width=2)
        line.set_style(array.get(reglines_lrgc, x), style=line.style_dotted)
        line.set_extend(array.get(reglines_lrgc, x), extend=extend.none)

    array.set(reglines_lrgc, x, line.new(x1=bar_index - (len_lrgc - 1), y1=y1_ + dev * devlen_lrgc * (x - 1), x2=bar_index, y2=y2_ + dev * devlen_lrgc * (x - 1), color=array.get(colors_lrgc, math.round(math.max(math.sign(slope), 0))), style=x % 2 == 1 ? line.style_solid : line.style_dashed, width=widt_lrgc, extend=extendit_lrgc ? extend.right : extend.none))
if showfibo_lrgc
    for x = 0 to 3 by 1
        line.delete(array.get(fibolines_lrgc, x))
        array.set(fibolines_lrgc, x, line.new(x1=bar_index - (len_lrgc - 1), y1=y1_ - dev * devlen_lrgc + dev * devlen_lrgc * 2 * array.get(fibo_ratios_lrgc, x), x2=bar_index, y2=y2_ - dev * devlen_lrgc + dev * devlen_lrgc * 2 * array.get(fibo_ratios_lrgc, x), color=array.get(colors_lrgc, math.round(math.max(math.sign(slope), 0))), style=line.style_dotted, width=widt_lrgc, extend=extendit_lrgc ? extend.right : extend.none))

var label sidelab_lrgc = label.new(x=bar_index - (len_lrgc - 1), y=y1_, text='S', size=size.large)
txt_lrgc = slope > 0 ? slope > slope[1] ? '⇑' : '⇗' : slope < 0 ? slope < slope[1] ? '⇓' : '⇘' : '⇒'
stl_lrgc = slope > 0 ? slope > slope[1] ? label.style_label_up : label.style_label_upper_right : slope < 0 ? slope < slope[1] ? label.style_label_down : label.style_label_lower_right : label.style_label_right
label.set_style(sidelab_lrgc, stl_lrgc)
label.set_text(sidelab_lrgc, txt_lrgc)
label.set_x(sidelab_lrgc, bar_index - (len_lrgc - 1))
label.set_y(sidelab_lrgc, slope > 0 ? y1_ - dev * devlen_lrgc : slope < 0 ? y1_ + dev * devlen_lrgc : y1_)
label.set_color(sidelab_lrgc, slope > 0 ? upcol_lrgc : slope < 0 ? dncol_lrgc : color.blue)

alertcondition(outofchannel_lrgc, title='Channel Broken', message='Channel Broken')

// direction
trendisup_lrgc = math.sign(slope) != math.sign(slope[1]) and slope > 0
trendisdown_lrgc = math.sign(slope) != math.sign(slope[1]) and slope < 0
alertcondition(trendisup_lrgc, title='Up trend', message='Up trend')
alertcondition(trendisdown_lrgc, title='Down trend', message='Down trend')



//END LINEAR REGRESSION CHANNEL
//*******************************************************
