module smtp.utils;

import std.datetime;
import std.string;
import std.conv;
import std.array;

string writeUFC2822DateHeader(SysTime time)
{
        int offsetHours, offsetMinutes;
        time.utcOffset.split!("hours","minutes")(offsetHours, offsetMinutes);
        static immutable monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "June", "July", "Aug", "Sep", "Oct", "Nov", "Dec"];
        static immutable dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
        auto email2822Header = appender!string();
        email2822Header.put(dayNames[time.dayOfWeek]);
        email2822Header.put(", ");
        email2822Header.put(forceDigitWrite(time.day,2,false));
        email2822Header.put(' ');
        email2822Header.put(monthNames[time.month-1]);
        email2822Header.put(' ');
        email2822Header.put(forceDigitWrite(time.year,4,false));
        email2822Header.put(' ');
        email2822Header.put(forceDigitWrite(time.hour, 2, false));
        email2822Header.put(':');
        email2822Header.put(forceDigitWrite(time.minute,2,false));
        email2822Header.put(':');
        email2822Header.put(forceDigitWrite(time.second,2,false));
        email2822Header.put(' ');
        email2822Header.put(forceDigitWrite(offsetHours,2,true));
        email2822Header.put(forceDigitWrite(offsetMinutes,2,false));
        return email2822Header.data;
}

string forceDigitWrite(int number, int digits, bool signed) 
{
        auto output = appender!(string);
        int nextNumber;
        int digit;
        int exponent = 10^^(digits-1);
        if (signed)
        {
                if (number >= 0)
                {
                        output.put( "+");
                }
                else
                {
                        output.put("-");
                }
        }
        if (number < 0)
                number = 0 - number;
        while (exponent >= 1 )
        {
                digit = (number / exponent);
                output.put(cast(char)(digit + '0'));
                number -= (digit * exponent);
                exponent /= 10;
        }
        return output.data;
}