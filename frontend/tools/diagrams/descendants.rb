def descendants(ancestor, exceptions = ['Module', 'Class', 'Errno', 'Opal'], constant = Object, result = [], visiteds = {})
  constant.constants.each do |c|
    next if exceptions.include?(c)
    c_ = constant.const_get(c)
    next if native?(c_) || !c_.respond_to?('name')
    next unless c_
    next if visiteds[c_.name]
    visiteds[c_.name] = true
    result << c_ if c_.respond_to?('<') && (c_ < ancestor rescue false)
    descendants(ancestor, exceptions, c_, result, visiteds) if c_.respond_to?(:constants)
  end
  return result
end
