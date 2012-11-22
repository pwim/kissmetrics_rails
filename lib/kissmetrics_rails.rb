require "kissmetrics_rails/version"

module KissmetricsRails
  class Railtie < Rails::Railtie
    config.kissmetrics_rails = ActiveSupport::OrderedOptions.new
    initializer 'kissmetrics_rails' do |app|
      ActiveSupport.on_load :action_controller do
        include KissmetricsRails::InstanceMethods
        helper KissmetricsRails::KissmetricsHelper
      end
    end
  end

  module InstanceMethods
    def track_with_kissmetrics(s)
      kissmetrics_queue << s
    end

    def register_with_kissmetrics
      session[:register_with_kissmetrics] ||= {}
    end

    def kissmetrics_queue
      session[:kissmetrics_queue] ||= []
    end
  end

  module KissmetricsHelper
    def kissmetrics_events_tag
      return unless Rails.application.config.kissmetrics_rails.api_key
      properties = session.delete(:register_with_kissmetrics) || {}
      queue = session.delete(:kissmetrics_queue) || []

      events = queue.map do |s|
        "_kmq.push(['record', '#{s}', #{properties.to_json}]);"
      end

      javascript_tag(events)
    end

    def kissmetrics_identify_tag(email)
      return unless Rails.application.config.kissmetrics_rails.api_key
      javascript_tag("_kmq.push(['identify', '#{email}']);")
    end

    def kissmetrics_init_tag
      return unless Rails.application.config.kissmetrics_rails.api_key
s = <<EOD 
  var _kmq = _kmq || [];
  var _kmk = _kmk || '#{Rails.application.config.kissmetrics_rails.api_key}';
  function _kms(u){
    setTimeout(function(){
      var d = document, f = d.getElementsByTagName('script')[0],
      s = d.createElement('script');
      s.type = 'text/javascript'; s.async = true; s.src = u;
      f.parentNode.insertBefore(s, f);
    }, 1);
  }
  _kms('//i.kissmetrics.com/i.js');
  _kms('//doug1izaerwt3.cloudfront.net/' + _kmk + '.1.js');
EOD
      javascript_tag(s)
    end
  end
end
