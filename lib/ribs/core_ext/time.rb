
class Time
  JavaSqlDate = java.sql.Date
  JavaSqlTime = java.sql.Time
  JavaSqlTimestamp = java.sql.Timestamp

  def to_java_sql_date
    JavaSqlDate.new(self.to_i*1000)
  end

  def to_java_sql_time
    JavaSqlTime.new(self.to_i*1000)
  end

  def to_java_sql_time_stamp
    JavaSqlTimestamp.new(self.to_i*1000)
  end
end
