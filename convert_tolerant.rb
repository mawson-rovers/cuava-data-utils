require "JSON"
require "ostruct"
require 'date'

input = ARGF.readlines

eps_records = []
adcs_records = []

line = input.shift

class Hash
  def to_o
    JSON.parse to_json, object_class: OpenStruct
  end
end

def narrow_eps(record_h)
  powerChannelNames = {
    '00': 'VHF/UHF',
    '03': 'Payload computer',
    '05': 'OBC',
    '02': 'Specific payload',
    '04': 'Specific payload',
    '08': 'ADCS',
    '12': 'Payloads',
    '13': 'GPS',
    '14': 'S-band'
  }

  record = record_h.to_o

  narrowed = {
    time: record.timestamp,
    batt_temp2: record.batt_temp2,
    batt_temp3: record.batt_temp3,
    batt_volt: record.vip_batt_input.volt,
    batt_curr: record.vip_batt_input.curr,
    batt_power: record.vip_batt_input.pwr,
    ccd1_volt: record.ccd1.volt_out_mppt,
    ccd1_curr: record.ccd1.curr_out_mppt,
    ccd2_volt: record.ccd1.volt_out_mppt,
    ccd2_curr: record.ccd1.curr_out_mppt,
    ccd3_volt: record.ccd1.volt_out_mppt,
    ccd3_curr: record.ccd1.curr_out_mppt,
    ccd4_volt: record.ccd1.volt_out_mppt,
    ccd4_curr: record.ccd1.curr_out_mppt,
    ccd5_volt: record.ccd1.volt_out_mppt,
    ccd5_curr: record.ccd1.curr_out_mppt
  }

  powerChannelNames.keys.each { |key|
      vipChannel = 'vip_cnt_ch' + key.to_s
      narrowed["ch#{key}_volt"] = record[vipChannel].volt
      narrowed["ch#{key}_curr"] = record[vipChannel].curr
      narrowed["ch#{key}_power"] = record[vipChannel].pwr
  }

  return narrowed
end

def narrow_adcs(record_h)
  record = record_h.to_o

  {
      roll_angle: record.estimated_roll_angle,
      pitch_angle: record.estimated_pitch_angle,
      yaw_angle: record.estimated_yaw_angle,
      x_angular_rate: record.estimated_x_angular_rate,
      y_angular_rate: record.estimated_y_angular_rate,
      z_angular_rate: record.estimated_z_angular_rate
  }
end

while !line.nil?

  sat = line.split(/: /)[1].gsub("\"","").chomp
  date = input.shift.split(/: /)[1].chomp
  header = input.shift

  case header
  when /^EPS:/
    record = "{"

    line = input.shift
    while !line.nil? && !(line =~ /^Sat:/)
        record += line
        line = input.shift
    end

    timestamped_record = { timestamp: date, eps: JSON.parse!(record) }
    timestamped_record[:eps][:timestamp] = date

    eps_records << timestamped_record
  when /^ADCS State:/
    record = "{"

    line = input.shift
    while !line.nil? && !(line =~ /^ADCS Measurements:/)
        record += line
        line = input.shift
    end

    adcs_json = JSON.parse!(record)["AdcsStateAll"]
    unless adcs_json.nil? # This can happen with corrupted WS-1 ADCS data
      timestamped_record = { timestamp: date, adcs: adcs_json }
      adcs_records << timestamped_record
    end

    line = input.shift
    while !line.nil? && !(line =~ /^Sat:/)
        line = input.shift
    end
  else
    line = input.shift
    while !line.nil? && !(line =~ /^Sat:/)
        line = input.shift
    end
  end

end



latest_eps = narrow_eps(eps_records.reject { _1[:eps]["vip_batt_input"]["volt"] <= 0 }.sort { |a,b| DateTime.rfc3339(a[:eps][:timestamp]) <=> DateTime.rfc3339(b[:eps][:timestamp]) }.last[:eps])
latest_adcs = narrow_adcs(adcs_records.last[:adcs])

timeseries = [latest_eps.keys]
timeseries.concat(
  eps_records
    .reject { _1[:eps]["vip_batt_input"]["volt"] <= 0 }
    .map{ |v| narrow_eps(v[:eps]) }
    .map { _1.values }
    .sort { |a,b| DateTime.rfc3339(a.first) <=> DateTime.rfc3339(b.first) }
    .uniq { DateTime.rfc3339(_1.first) }
)

fe = {
  latest: latest_eps.merge(latest_adcs),
  timeseries: timeseries
}

puts JSON.generate(fe)
