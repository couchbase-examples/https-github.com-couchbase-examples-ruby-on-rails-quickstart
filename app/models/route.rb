class Route
  attr_accessor :airline, :airlineid, :sourceairport, :destinationairport, :stops, :equipment, :schedule, :distance

  def initialize(attributes)
    @airline = attributes['airline']
    @airlineid = attributes['airlineid']
    @sourceairport = attributes['sourceairport']
    @destinationairport = attributes['destinationairport']
    @stops = attributes['stops'].to_i
    @equipment = attributes['equipment']
    @schedule = attributes['schedule'].map do |sched|
      {
        'day' => sched['day'].to_i,
        'utc' => sched['utc'],
        'flight' => sched['flight']
      }
    end
    @distance = attributes['distance'].to_f
  end

  def self.find(id)
    result = ROUTE_COLLECTION.get(id)
    new(result.content) if result.success?
  rescue Couchbase::Error::DocumentNotFound
    nil
  end

  def self.create(id, attributes)
    required_fields = %w[airline airlineid sourceairport destinationairport stops equipment distance schedule]
    missing_fields = required_fields - attributes.keys
    extra_fields = attributes.keys - required_fields

    raise ArgumentError, "Missing fields: #{missing_fields.join(', ')}" if missing_fields.any?

    raise ArgumentError, "Extra fields: #{extra_fields.join(', ')}" if extra_fields.any?

    formatted_attributes = {
      'airline' => attributes['airline'],
      'airlineid' => attributes['airlineid'],
      'sourceairport' => attributes['sourceairport'],
      'destinationairport' => attributes['destinationairport'],
      'stops' => attributes['stops'].to_i,
      'equipment' => attributes['equipment'],
      'schedule' => attributes['schedule'].map do |sched|
        {
          'day' => sched['day'].to_i,
          'utc' => sched['utc'],
          'flight' => sched['flight']
        }
      end,
      'distance' => attributes['distance'].to_f
    }
    ROUTE_COLLECTION.insert(id, formatted_attributes)
    new(formatted_attributes)
  rescue Couchbase::Error::DocumentExists
    raise Couchbase::Error::DocumentExists, "Route with ID #{id} already exists"
  end

  def update(id, attributes)
    required_fields = %w[airline airlineid sourceairport destinationairport stops equipment distance schedule]
    missing_fields = required_fields - attributes.keys
    extra_fields = attributes.keys - required_fields

    raise ArgumentError, "Missing fields: #{missing_fields.join(', ')}" if missing_fields.any?

    raise ArgumentError, "Extra fields: #{extra_fields.join(', ')}" if extra_fields.any?

    formatted_attributes = {
      'airline' => attributes['airline'],
      'airlineid' => attributes['airlineid'],
      'sourceairport' => attributes['sourceairport'],
      'destinationairport' => attributes['destinationairport'],
      'stops' => attributes['stops'].to_i,
      'equipment' => attributes['equipment'],
      'schedule' => attributes['schedule'].map do |sched|
        {
          'day' => sched['day'].to_i,
          'utc' => sched['utc'],
          'flight' => sched['flight']
        }
      end,
      'distance' => attributes['distance'].to_f
    }
    ROUTE_COLLECTION.upsert(id, formatted_attributes)
    self.class.new(formatted_attributes)
  rescue Couchbase::Error::DocumentNotFound
    raise Couchbase::Error::DocumentNotFound, "Route with ID #{id} not found"
  end

  def destroy(id)
    ROUTE_COLLECTION.remove(id)
    true
  rescue Couchbase::Error::DocumentNotFound
    false
  end
end
