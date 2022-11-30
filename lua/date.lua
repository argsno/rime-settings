-- Get day of a week at year beginning 
--(tm can be any date and will be forced to 1st of january same year)
-- return 1=mon 7=sun
function getYearBeginDayOfWeek(tm)
  yearBegin = os.time{year=os.date("*t",tm).year,month=1,day=1}
  yearBeginDayOfWeek = tonumber(os.date("%w",yearBegin))
  -- sunday correct from 0 -> 7
  if(yearBeginDayOfWeek == 0) then yearBeginDayOfWeek = 7 end
  return yearBeginDayOfWeek
end

-- tm: date (as retruned fro os.time)
-- returns basic correction to be add for counting number of week
--  weekNum = math.floor((dayOfYear + returnedNumber) / 7) + 1 
-- (does not consider correctin at begin and end of year) 
function getDayAdd(tm)
  yearBeginDayOfWeek = getYearBeginDayOfWeek(tm)
  if(yearBeginDayOfWeek < 5 ) then
    -- first day is week 1
    dayAdd = (yearBeginDayOfWeek - 2)
  else 
    -- first day is week 52 or 53
    dayAdd = (yearBeginDayOfWeek - 9)
  end  
  return dayAdd
end
-- tm is date as returned from os.time()
-- return week number in year based on ISO8601 
-- (week with 1st thursday since Jan 1st (including) is considered as Week 1)
-- (if Jan 1st is Fri,Sat,Sun then it is part of week number from last year -> 52 or 53)
function getWeekNumberOfYear(tm)
  dayOfYear = os.date("%j",tm)
  dayAdd = getDayAdd(tm)
  dayOfYearCorrected = dayOfYear + dayAdd
  if(dayOfYearCorrected < 0) then
    -- week of last year - decide if 52 or 53
    lastYearBegin = os.time{year=os.date("*t",tm).year-1,month=1,day=1}
    lastYearEnd = os.time{year=os.date("*t",tm).year-1,month=12,day=31}
    dayAdd = getDayAdd(lastYearBegin)
    dayOfYear = dayOfYear + os.date("%j",lastYearEnd)
    dayOfYearCorrected = dayOfYear + dayAdd
  end  
  weekNum = math.floor((dayOfYearCorrected) / 7) + 1
  if( (dayOfYearCorrected > 0) and weekNum == 53) then
    -- check if it is not considered as part of week 1 of next year
    nextYearBegin = os.time{year=os.date("*t",tm).year+1,month=1,day=1}
    yearBeginDayOfWeek = getYearBeginDayOfWeek(nextYearBegin)
    if(yearBeginDayOfWeek < 5 ) then
      weekNum = 1
    end  
  end  
  return weekNum
end
function date_translator(input, seg)
    if (input == "date") then
        --- Candidate(type, start, end, text, comment)
        yield(Candidate("date", seg.start, seg._end, os.date("%Y-%m-%d"), ""))
        yield(Candidate("date", seg.start, seg._end, os.date("%Y年%m月%d日"), ""))
        yield(Candidate("date", seg.start, seg._end, os.date("%m-%d"), ""))
        yield(Candidate("date", seg.start, seg._end, os.date("%Y/%m/%d"), ""))
    end
    if (input == "ndate") then
        --- Candidate(type, start, end, text, comment)
        yield(Candidate("ndate", seg.start, seg._end, os.date("%Y-%m-%d", os.time() + 24*60*60), ""))
        yield(Candidate("ndate", seg.start, seg._end, os.date("%Y年%m月%d日", os.time() + 24*60*60), ""))
        yield(Candidate("ndate", seg.start, seg._end, os.date("%m-%d", os.time() + 24*60*60), ""))
        yield(Candidate("ndate", seg.start, seg._end, os.date("%Y/%m/%d", os.time() + 24*60*60), ""))
    end
    if (input == "time") then
        --- Candidate(type, start, end, text, comment)
        yield(Candidate("time", seg.start, seg._end, os.date("%H:%M"), ""))
        yield(Candidate("time", seg.start, seg._end, os.date("%H:%M:%S"), ""))
    end
    if (input == "week") then
        local weakTab = {'日', '一', '二', '三', '四', '五', '六'}
        yield(Candidate("week", seg.start, seg._end, "周"..weakTab[tonumber(os.date("%w")+1)], ""))
        yield(Candidate("week", seg.start, seg._end, "星期"..weakTab[tonumber(os.date("%w")+1)], ""))
        yield(Candidate("week", seg.start, seg._end, "礼拜"..weakTab[tonumber(os.date("%w")+1)], ""))
        yield(Candidate("week", seg.start, seg._end, "第"..getWeekNumberOfYear(os.time()).."周", ""))
    end
end

--- 过滤器：单字在先
function single_char_first_filter(input)
    local l = {}
    for cand in input:iter() do
        if (utf8.len(cand.text) == 1) then
            yield(cand)
        else
            table.insert(l, cand)
        end
    end
    for cand in ipairs(l) do
        yield(cand)
    end
end