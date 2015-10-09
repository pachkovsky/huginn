module Agents
  class BeeperAgent < Agent

    cannot_be_scheduled!
    cannot_create_events!

    API_BASE = 'https://api.beeper.io/api'.freeze

    MESSAGE_TYPES = %w(message image event location task).freeze

    TYPE_TO_ATTRIBUTES = {
      'message'  => %w(text),
      'image'    => %w(text image),
      'event'    => %w(text start_time end_time),
      'location' => %w(text latitude longitude),
      'task'     => %w(text)
    }.freeze

    def default_options
      {
        'type'       => 'message',
        'app_id'     => '',
        'api_key'    => '',
        'sender_id'  => '',
        'phone'      => '',

        'text'       => '{{title}}',
        'image'      => '{{url}}',
        'start_time' => '',
        'end_time'   => '',
        'latitude'   => '',
        'longitude'  => ''
      }
    end

    def working?
      received_event_without_error?
    end

    def receive(incoming_events)
      incoming_events.each do |event|
        log(send_message(event))
      end
    end

    def send_message(event)
      mo = interpolated(event)
      begin
        HTTParty.post(endpoint_for(mo['type']), body: payload_for(mo),
          headers: credentials)
      rescue HTTParty::Error  => e
        error(e.message)
      end
    end

    private

    def credentials
      {
        'X-Beeper-Application-Id' => options['app_id'],
        'X-Beeper-REST-API-Key'   => options['api_key'],
        'Content-Type' => 'application/json'
      }
    end

    def payload_for(mo)
      payload = mo.slice(*TYPE_TO_ATTRIBUTES[mo['type']], 'sender_id', 'phone',
        'group_id').to_json
      log(payload)
      payload
    end

    def endpoint_for(type)
      "#{API_BASE}/#{type}s.json"
    end
  end
end