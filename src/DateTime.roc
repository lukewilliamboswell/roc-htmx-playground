import pf.UnixTime
import gregorian.Time

DateTime := [].{
	now_utc! : () => Str
	now_utc! = ||
		(Time.unix_epoch + UnixTime.now!().seconds_since_epoch()).iso8601()

	Display :: Str.{
		from_local_storage : Str -> Display
		from_local_storage = |value| Display.(format_local(value))

		to_str : Display -> Str
		to_str = |Display.(value)| value
	}
}

format_local : Str -> Str
format_local = |value|
	match value.split_on("T") {
		[date, time, ..] => {
			date_label = match date.split_on("-") {
				[year, month, day, ..] => "${day} ${month_label(month)} ${year}"
				_ => date
			}
			time_label = match time.split_on(":") {
				[hour, minute, ..] => "${hour}:${minute}"
				_ => time
			}
			"${date_label}, ${time_label}"
		}
		_ => value
	}

month_label : Str -> Str
month_label = |month|
	match month {
		"01" => "Jan"
		"02" => "Feb"
		"03" => "Mar"
		"04" => "Apr"
		"05" => "May"
		"06" => "Jun"
		"07" => "Jul"
		"08" => "Aug"
		"09" => "Sep"
		"10" => "Oct"
		"11" => "Nov"
		"12" => "Dec"
		_ => month
	}

expect DateTime.Display.from_local_storage("2026-07-28T18:36").to_str()
	== "28 Jul 2026, 18:36"
