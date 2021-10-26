
// This source code is subject to the terms of the Mozilla Public License 2.0 at https://mozilla.org/MPL/2.0/
// @ mrhili

//@version=5


indicator(title='combine stragegies 2', shorttitle='CMB2', overlay=true, format=format.inherit , max_bars_back=5000)





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


//BEAr and bull findeR


colors_obf = input.string(title='Color Scheme', defval='BRIGHT', options=['DARK', 'BRIGHT'])
periods_obf = input(5, 'Relevant Periods to identify OB')  // Required number of subsequent candles in the same direction to identify Order Block
threshold_obf = input.float(0.0, 'Min. Percent move to identify OB', step=0.1)  // Required minimum % move (from potential OB close to last subsequent candle to identify Order Block)
usewicks_obf = input(false, 'Use whole range [High/Low] for OB marking?')  // Display High/Low range for each OB instead of Open/Low for Bullish / Open/High for Bearish
showbull_obf = input(true, 'Show latest Bullish Channel?')  // Show Channel for latest Bullish OB?
showbear_obf = input(true, 'Show latest Bearish Channel?')  // Show Channel for latest Bearish OB?
showdocu_obf = input(false, 'Show Label for documentation tooltip?')  // Show Label which shows documentation as tooltip?
info_pan_obf = input(false, 'Show Latest OB Panel?')  // Show Info Panel with latest OB Stats

ob_period_obf = periods_obf + 1  // Identify location of relevant Order Block candle
absmove_obf = math.abs(close[ob_period_obf] - close[1]) / close[ob_period_obf] * 100  // Calculate absolute percent move from potential OB to last candle of subsequent candles
relmove_obf = absmove_obf >= threshold_obf  // Identify "Relevant move" by comparing the absolute move to the threshold

// Color Scheme
bullcolor_obf = colors_obf == 'DARK' ? color.white : color.green
bearcolor_obf = colors_obf == 'DARK' ? color.blue : color.red

// Bullish Order Block Identification
bullishOB_obf = close[ob_period_obf] < open[ob_period_obf]  // Determine potential Bullish OB candle (red candle)

int upcandles_obf = 0
for i = 1 to periods_obf by 1
    upcandles_obf := upcandles_obf + (close[i] > open[i] ? 1 : 0)  // Determine color of subsequent candles (must all be green to identify a valid Bearish OB)
    upcandles_obf

OB_bull_obf = bullishOB_obf and upcandles_obf == periods_obf and relmove_obf  // Identification logic (red OB candle & subsequent green candles)
OB_bull_high_obf = OB_bull_obf ? usewicks_obf ? high[ob_period_obf] : open[ob_period_obf] : na  // Determine OB upper limit (Open or High depending on input)
OB_bull_low_obf = OB_bull_obf ? low[ob_period_obf] : na  // Determine OB lower limit (Low)
OB_bull_avg_obf = (OB_bull_high_obf + OB_bull_low_obf) / 2  // Determine OB middle line


// Bearish Order Block Identification
bearishOB_obf = close[ob_period_obf] > open[ob_period_obf]  // Determine potential Bearish OB candle (green candle)

int downcandles_obf = 0
for i = 1 to periods_obf by 1
    downcandles_obf := downcandles_obf + (close[i] < open[i] ? 1 : 0)  // Determine color of subsequent candles (must all be red to identify a valid Bearish OB)
    downcandles_obf

OB_Bear_obf = bearishOB_obf and downcandles_obf == periods_obf and relmove_obf  // Identification logic (green OB candle & subsequent green candles)
OB_Bear_high_obf = OB_Bear_obf ? high[ob_period_obf] : na  // Determine OB upper limit (High)
OB_Bear_low_obf = OB_Bear_obf ? usewicks_obf ? low[ob_period_obf] : open[ob_period_obf] : na  // Determine OB lower limit (Open or Low depending on input)
OB_Bear_avg_obf = (OB_Bear_low_obf + OB_Bear_high_obf) / 2  // Determine OB middle line


// Plotting

plotshape(OB_bull_obf, title='Bullish OB', style=shape.triangleup, color=bullcolor_obf, textcolor=bullcolor_obf, size=size.tiny, location=location.belowbar, offset=-ob_period_obf, text='Bullish OB')  // Bullish OB Indicator
bull1_obf = plot(OB_bull_high_obf, title='Bullish OB High', style=plot.style_linebr, color=bullcolor_obf, offset=-ob_period_obf, linewidth=3)  // Bullish OB Upper Limit
bull2_obf = plot(OB_bull_low_obf, title='Bullish OB Low', style=plot.style_linebr, color=bullcolor_obf, offset=-ob_period_obf, linewidth=3)  // Bullish OB Lower Limit
fill(bull1_obf, bull2_obf, color=bullcolor_obf, title='Bullish OB fill', transp=0)  // Fill Bullish OB
plotshape(OB_bull_avg_obf, title='Bullish OB Average', style=shape.cross, color=bullcolor_obf, size=size.normal, location=location.absolute, offset=-ob_period_obf)  // Bullish OB Average


plotshape(OB_Bear_obf, title='Bearish OB', style=shape.triangledown, color=bearcolor_obf, textcolor=bearcolor_obf, size=size.tiny, location=location.abovebar, offset=-ob_period_obf, text='Bearish OB')  // Bearish OB Indicator
bear1_obf = plot(OB_Bear_low_obf, title='Bearish OB Low', style=plot.style_linebr, color=bearcolor_obf, offset=-ob_period_obf, linewidth=3)  // Bearish OB Lower Limit
bear2_obf = plot(OB_Bear_high_obf, title='Bearish OB High', style=plot.style_linebr, color=bearcolor_obf, offset=-ob_period_obf, linewidth=3)  // Bearish OB Upper Limit
fill(bear1_obf, bear2_obf, color=bearcolor_obf, title='Bearish OB fill', transp=0)  // Fill Bearish OB
plotshape(OB_Bear_avg_obf, title='Bearish OB Average', style=shape.cross, color=bearcolor_obf, size=size.normal, location=location.absolute, offset=-ob_period_obf)  // Bullish OB Average

var line linebull1_obf = na  // Bullish OB average 
var line linebull2_obf = na  // Bullish OB open
var line linebull3_obf = na  // Bullish OB low
var line linebear1_obf = na  // Bearish OB average
var line linebear2_obf = na  // Bearish OB high
var line linebear3_obf = na  // Bearish OB open


if OB_bull_obf and showbull_obf
    line.delete(linebull1_obf)
    linebull1_obf := line.new(x1=bar_index, y1=OB_bull_avg_obf, x2=bar_index - 1, y2=OB_bull_avg_obf, extend=extend.left, color=bullcolor_obf, style=line.style_solid, width=1)

    line.delete(linebull2_obf)
    linebull2_obf := line.new(x1=bar_index, y1=OB_bull_high_obf, x2=bar_index - 1, y2=OB_bull_high_obf, extend=extend.left, color=bullcolor_obf, style=line.style_dashed, width=1)

    line.delete(linebull3_obf)
    linebull3_obf := line.new(x1=bar_index, y1=OB_bull_low_obf, x2=bar_index - 1, y2=OB_bull_low_obf, extend=extend.left, color=bullcolor_obf, style=line.style_dashed, width=1)
    linebull3_obf

if OB_Bear_obf and showbear_obf
    line.delete(linebear1_obf)
    linebear1_obf := line.new(x1=bar_index, y1=OB_Bear_avg_obf, x2=bar_index - 1, y2=OB_Bear_avg_obf, extend=extend.left, color=bearcolor_obf, style=line.style_solid, width=1)

    line.delete(linebear2_obf)
    linebear2_obf := line.new(x1=bar_index, y1=OB_Bear_high_obf, x2=bar_index - 1, y2=OB_Bear_high_obf, extend=extend.left, color=bearcolor_obf, style=line.style_dashed, width=1)

    line.delete(linebear3_obf)
    linebear3_obf := line.new(x1=bar_index, y1=OB_Bear_low_obf, x2=bar_index - 1, y2=OB_Bear_low_obf, extend=extend.left, color=bearcolor_obf, style=line.style_dashed, width=1)
    linebear3_obf


// Alerts for Order Blocks Detection

alertcondition(OB_bull_obf, title='New Bullish OB detected', message='New Bullish OB detected - This is NOT a BUY signal!')
alertcondition(OB_Bear_obf, title='New Bearish OB detected', message='New Bearish OB detected - This is NOT a SELL signal!')

// Print latest Order Blocks in Data Window

var latest_bull_high_obf = 0.0  // Variable to keep latest Bull OB high
var latest_bull_avg_obf = 0.0  // Variable to keep latest Bull OB average
var latest_bull_low_obf = 0.0  // Variable to keep latest Bull OB low
var latest_bear_high_obf = 0.0  // Variable to keep latest Bear OB high
var latest_bear_avg_obf = 0.0  // Variable to keep latest Bear OB average
var latest_bear_low_obf = 0.0  // Variable to keep latest Bear OB low

// Assign latest values to variables
if OB_bull_high_obf > 0
    latest_bull_high_obf := OB_bull_high_obf
    latest_bull_high_obf

if OB_bull_avg_obf > 0
    latest_bull_avg_obf := OB_bull_avg_obf
    latest_bull_avg_obf

if OB_bull_low_obf > 0
    latest_bull_low_obf := OB_bull_low_obf
    latest_bull_low_obf

if OB_Bear_high_obf > 0
    latest_bear_high_obf := OB_Bear_high_obf
    latest_bear_high_obf

if OB_Bear_avg_obf > 0
    latest_bear_avg_obf := OB_Bear_avg_obf
    latest_bear_avg_obf

if OB_Bear_low_obf > 0
    latest_bear_low_obf := OB_Bear_low_obf
    latest_bear_low_obf

// Plot invisible characters to be able to show the values in the Data Window
plotchar(latest_bull_high_obf, char=' ', location=location.abovebar, color=color.new(#777777, 100), size=size.tiny, title='Latest Bull High')
plotchar(latest_bull_avg_obf, char=' ', location=location.abovebar, color=color.new(#777777, 100), size=size.tiny, title='Latest Bull Avg')
plotchar(latest_bull_low_obf, char=' ', location=location.abovebar, color=color.new(#777777, 100), size=size.tiny, title='Latest Bull Low')
plotchar(latest_bear_high_obf, char=' ', location=location.abovebar, color=color.new(#777777, 100), size=size.tiny, title='Latest Bear High')
plotchar(latest_bear_avg_obf, char=' ', location=location.abovebar, color=color.new(#777777, 100), size=size.tiny, title='Latest Bear Avg')
plotchar(latest_bear_low_obf, char=' ', location=location.abovebar, color=color.new(#777777, 100), size=size.tiny, title='Latest Bear Low')


//InfoPanel for latest Order Blocks

draw_InfoPanel(_text, _x, _y, font_size) =>
    var label la_panel = na
    label.delete(la_panel)
    la_panel := label.new(x=_x, y=_y, text=_text, xloc=xloc.bar_time, yloc=yloc.price, color=color.new(#383838, 5), style=label.style_label_left, textcolor=color.white, size=font_size)
    la_panel

info_panel_x_obf = time_close + math.round(ta.change(time) * 100)
info_panel_y_obf = close

title_obf = 'LATEST ORDER BLOCKS'
row0_obf = '-----------------------------------------------------'
row1_obf = ' Bullish - High: ' + str.tostring(latest_bull_high_obf, '#.##')
row2_obf = ' Bullish - Avg: ' + str.tostring(latest_bull_avg_obf, '#.##')
row3_obf = ' Bullish - Low: ' + str.tostring(latest_bull_low_obf, '#.##')
row4_obf = '-----------------------------------------------------'
row5_obf = ' Bearish - High: ' + str.tostring(latest_bear_high_obf, '#.##')
row6_obf = ' Bearish - Avg: ' + str.tostring(latest_bear_avg_obf, '#.##')
row7_obf = ' Bearish - Low: ' + str.tostring(latest_bear_low_obf, '#.##')

panel_text_obf = '\n' + title_obf + '\n' + row0_obf + '\n' + row1_obf + '\n' + row2_obf + '\n' + row3_obf + '\n' + row4_obf + '\n\n' + row5_obf + '\n' + row6_obf + '\n' + row7_obf + '\n'

if info_pan_obf
    draw_InfoPanel(panel_text_obf, info_panel_x_obf, info_panel_y_obf, size.normal)


// === Label for Documentation/Tooltip ===
chper_obf = time - time[1]
chper_obf := ta.change(chper_obf) > 0 ? chper_obf[1] : chper_obf

// === Tooltip text ===

var vartooltip_obf = 'Indicator to help identifying instituational Order Blocks. Often these blocks signal the beginning of a strong move, but there is a high probability, that these prices will be revisited at a later point in time again and therefore are interesting levels to place limit orders. \nBullish Order block is the last down candle before a sequence of up candles. \nBearish Order Block is the last up candle before a sequence of down candles. \nIn the settings the number of required sequential candles can be adjusted. \nFurthermore a %-threshold can be entered which the sequential move needs to achieve in order to validate a relevant Order Block. \nChannels for the last Bullish/Bearish Block can be shown/hidden.'

// === Print Label ===
var label l_docu = na
label.delete(l_docu)

if showdocu_obf
    l_docu := label.new(x=time + chper_obf * 35, y=close, text='DOCU OB', color=color.gray, textcolor=color.white, style=label.style_label_center, xloc=xloc.bar_time, yloc=yloc.price, size=size.tiny, textalign=text.align_left, tooltip=vartooltip_obf)
    l_docu




//AND BULL BEAr findeR
//**************************************
//START EXTRAPOLATED PIVOTE CONNECTOR


//----
length_ex_p_conn = input(100)
astart_ex_p_conn = input(1, 'A-High Position')
aend_ex_p_conn = input(0, 'B-High Position')
bstart_ex_p_conn = input(1, 'A-Low Position')
bend_ex_p_conn = input(0, 'B-Low Position')
csrc_ex_p_conn = input(false, 'Use Custom Source ?')
src_ex_p_conn = input(close, 'Custom Source')
//----
up_ex_p_conn = ta.pivothigh(csrc_ex_p_conn ? src_ex_p_conn : high, length_ex_p_conn, length_ex_p_conn)
dn_ex_p_conn = ta.pivotlow(csrc_ex_p_conn ? src_ex_p_conn : low, length_ex_p_conn, length_ex_p_conn)
//----
n_ex_p_conn = bar_index
a1_ex_p_conn = ta.valuewhen(not na(up_ex_p_conn), n_ex_p_conn, astart_ex_p_conn)
b1_ex_p_conn = ta.valuewhen(not na(dn_ex_p_conn), n_ex_p_conn, bstart_ex_p_conn)
a2_ex_p_conn = ta.valuewhen(not na(up_ex_p_conn), n_ex_p_conn, aend_ex_p_conn)
b2_ex_p_conn = ta.valuewhen(not na(dn_ex_p_conn), n_ex_p_conn, bend_ex_p_conn)
//----
line upper_ex_p_conn = line.new(n_ex_p_conn[n_ex_p_conn - a1_ex_p_conn + length_ex_p_conn], up_ex_p_conn[n_ex_p_conn - a1_ex_p_conn], n_ex_p_conn[n_ex_p_conn - a2_ex_p_conn + length_ex_p_conn], up_ex_p_conn[n_ex_p_conn - a2_ex_p_conn], extend=extend.right, color=color.blue, width=2)
line lower_ex_p_conn = line.new(n_ex_p_conn[n_ex_p_conn - b1_ex_p_conn + length_ex_p_conn], dn_ex_p_conn[n_ex_p_conn - b1_ex_p_conn], n_ex_p_conn[n_ex_p_conn - b2_ex_p_conn + length_ex_p_conn], dn_ex_p_conn[n_ex_p_conn - b2_ex_p_conn], extend=extend.right, color=color.orange, width=2)
line.delete(upper_ex_p_conn[1])
line.delete(lower_ex_p_conn[1])
//----
label ahigh_ex_p_conn = label.new(n_ex_p_conn[n_ex_p_conn - a1_ex_p_conn + length_ex_p_conn], up_ex_p_conn[n_ex_p_conn - a1_ex_p_conn], 'A-High', color=color.blue, style=label.style_label_down, textcolor=color.white, size=size.small)
label bhigh_ex_p_conn = label.new(n_ex_p_conn[n_ex_p_conn - a2_ex_p_conn + length_ex_p_conn], up_ex_p_conn[n_ex_p_conn - a2_ex_p_conn], 'B-High', color=color.blue, style=label.style_label_down, textcolor=color.white, size=size.small)
label alow_ex_p_conn = label.new(n_ex_p_conn[n_ex_p_conn - b1_ex_p_conn + length_ex_p_conn], dn_ex_p_conn[n_ex_p_conn - b1_ex_p_conn], 'A-Low', color=color.orange, style=label.style_label_up, textcolor=color.white, size=size.small)
label blow_ex_p_conn = label.new(n_ex_p_conn[n_ex_p_conn - b2_ex_p_conn + length_ex_p_conn], dn_ex_p_conn[n_ex_p_conn - b2_ex_p_conn], 'B-Low', color=color.orange, style=label.style_label_up, textcolor=color.white, size=size.small)
label.delete(ahigh_ex_p_conn[1])
label.delete(bhigh_ex_p_conn[1])
label.delete(alow_ex_p_conn[1])
label.delete(blow_ex_p_conn[1])
//----
plot(up_ex_p_conn, 'Pivot High\'s', color.new(color.blue, 0), 4, style=plot.style_circles, offset=-length_ex_p_conn, join=true)
plot(dn_ex_p_conn, 'Pivot Low\'s', color.new(color.orange, 0), 4, style=plot.style_circles, offset=-length_ex_p_conn, join=true)



//END EXTRAPOLATED PIVOTE CONNECTOR
