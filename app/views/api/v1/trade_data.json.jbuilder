Jbuilder.encode do |json|
  @time_series.each do |key, value|
    json.send(key.to_sym, value)
  end
end
