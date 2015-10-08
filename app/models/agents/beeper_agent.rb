module Agents
  class BeeperAgent < Agent
    include FormConfigurable

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

    form_configurable :type, type: :array, values: MESSAGE_TYPES
    form_configurable :app_id
    form_configurable :api_key
    form_configurable :sender_id
    form_configurable :phone
    form_configurable :group_id

    form_configurable :text
    form_configurable :image
    form_configurable :start_time
    form_configurable :end_time
    form_configurable :latitude
    form_configurable :longitude

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
        response = HTTParty.post(endpoint_for(mo['type']), body: payload_for(mo),
          headers: credentials)
        response
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
      payload = mo.slice(*TYPE_TO_ATTRIBUTES[mo['type']], 'sender_id', 'phone').to_json
      log(payload)
      payload
    end

    def endpoint_for(type)
      "#{API_BASE}/#{type}s.json"
    end
  end
end