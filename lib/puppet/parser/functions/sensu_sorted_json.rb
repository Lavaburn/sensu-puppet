require 'json'

Puppet::Functions.create_function(:sensu_sorted_json) do
  def sensu_sorted_json(*args)
    raise(Puppet::ParseError, "sensu_sorted_json(): Wrong number of arguments " +
      "given (#{args.size} for 1 or 2)") unless args.size.between?(1,2)
    
    @@loop = 0
    
    unsorted_hash = args[0]      || {}
    pretty        = args[1]      || false
    indent_len    = 4

    unsorted_hash.reject! {|key, value| value == :undef }

    if pretty
      return sorted_pretty_generate(unsorted_hash, indent_len) << "\n"
    else
      return sorted_generate(unsorted_hash)
    end
  end

  def validate_keys(obj)
    Puppet.debug("hello")
    obj.keys.each do |k|
      case k
        when String
          Puppet.debug("Found a valid key: " << k)
        else
          raise(Puppet::ParseError, "Unable to use key of type <%s>" % k.class.to_s)
      end
    end
  end
  
  def sorted_generate(obj)
    case obj
      when Fixnum, Float, TrueClass, FalseClass, NilClass
        return obj.to_json
      when String
        # Convert quoted integers (string) to int
        return (obj.match(/\A[-]?[0-9]+\z/) ? obj.to_i : obj).to_json
      when Array
        arrayRet = []
        obj.each do |a|
          arrayRet.push(sorted_generate(a))
        end
        return "[" << arrayRet.join(',') << "]";
      when Hash
        ret = []
        validate_keys(obj)
        obj.keys.sort.each do |k|
          ret.push(k.to_s.to_json << ":" << sorted_generate(obj[k]))
        end
        return "{" << ret.join(",") << "}";
      else
        raise(Puppet::ParseError, "Unable to handle object of type <%s>" % obj.class.to_s)
    end
  end

  def sorted_pretty_generate(obj, indent_len=4)
    # Indent length
    indent = " " * indent_len
  
    case obj
  
      when Fixnum, Float, TrueClass, FalseClass, NilClass
        return obj.to_json
  
      when String
        # Convert quoted integers (string) to int
        return (obj.match(/\A[-]?[0-9]+\z/) ? obj.to_i : obj).to_json
  
      when Array
        arrayRet = []
  
        # We need to increase the loop count before #each so the objects inside are indented twice.
        # When we come out of #each we decrease the loop count so the closing brace lines up properly.
        #
        # If you start with @@loop = 1, the count will be as follows
        #
        # "start_join": [     <-- @@loop == 1
        #   "192.168.50.20",  <-- @@loop == 2
        #   "192.168.50.21",  <-- @@loop == 2
        #   "192.168.50.22"   <-- @@loop == 2
        # ] <-- closing brace <-- @@loop == 1
        #
        @@loop += 1
        obj.each do |a|
          arrayRet.push(sorted_pretty_generate(a, indent_len))
        end
        @@loop -= 1
  
        return "[\n#{indent * (@@loop + 1)}" << arrayRet.join(",\n#{indent * (@@loop + 1)}") << "\n#{indent * @@loop}]";
  
      when Hash
        ret = []
        validate_keys(obj)
  
        # This loop works in a similar way to the above
        @@loop += 1
        obj.keys.sort.each do |k|
          ret.push("#{indent * @@loop}" << k.to_json << ": " << sorted_pretty_generate(obj[k], indent_len))
        end
        @@loop -= 1
  
        return "{\n" << ret.join(",\n") << "\n#{indent * @@loop}}";
      else
        raise(Puppet::ParseError, "Unable to handle object of type <%s>" % obj.class.to_s)
    end
  end
end
