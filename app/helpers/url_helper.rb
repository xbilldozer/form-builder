module UrlHelper
  
  # Helper for appending hash attributes to a URL for ajax stuff
  def hash_for(url,hash_content = {})
    hash = []
    hash_content.each do |k,v|
      v = v.id if not (v.is_a?(Fixnum) || v.is_a?(String))
      hash << "#{k.to_s}=#{v}"
    end
    url << "##{hash.join("&")}"
    return url
  end
  
end