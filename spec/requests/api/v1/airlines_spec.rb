require 'rails_helper'
require 'swagger_helper'

RSpec.describe 'Airlines API', type: :request do
  describe 'GET /api/v1/airlines/{id}' do
    let(:airline_id) { 'airline_10' }
    let(:expected_airline) do
      {
        'id' => 10,
        'name' => '40-Mile Air',
        'iata' => 'Q5',
        'icao' => 'MLA',
        'callsign' => 'MILE-AIR',
        'country' => 'United States',
        'type' => 'airline'
      }
    end

    before do
      allow(AIRLINE_COLLECTION).to receive(:get).with(airline_id).and_return(double(success?: true, content: expected_airline))
    end

    it 'returns the airline' do
      get "/api/v1/airlines/#{airline_id}"

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq('application/json; charset=utf-8')
      expect(JSON.parse(response.body)).to eq(expected_airline)
    end
  end

  describe 'POST /api/v1/airlines/{id}' do
    let(:airline_id) { 'airline_post' }
    let(:airline_params) do
      {
        'id' => 11,
        'name' => '40-Mile Air',
        'iata' => 'Q5',
        'icao' => 'MLA',
        'callsign' => 'MILE-AIR',
        'country' => 'United States',
        'type' => 'airline'
      }
    end

    context 'when the airline is created successfully' do
      before do
        allow(AIRLINE_COLLECTION).to receive(:insert).with(airline_params).and_return(airline_id)
      end

      it 'returns the created airline' do
        post "/api/v1/airlines/#{airline_id}", params: { airline: airline_params }

        expect(response).to have_http_status(:created)
        expect(response.content_type).to eq('application/json; charset=utf-8')
        expect(JSON.parse(response.body)).to include(airline_params)
      end
    end

    context 'when the airline already exists' do
      before do
        allow(AIRLINE_COLLECTION).to receive(:insert).with(airline_params).and_raise(Couchbase::Error::DocumentExistsError)
      end

      it 'returns a conflict error' do
        post "/api/v1/airlines/#{airline_id}", params: { airline: airline_params }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to eq({ 'error' => 'Validation failed: Document already exists' })
      end
    end
  end

  describe 'PUT /api/v1/airlines/{id}' do
    let(:airline_id) { 'airline_put' }
    let(:airline_params) do
      {
        'id' => 11,
        'name' => '40-Mile Air',
        'iata' => 'U5',
        'icao' => 'UPD',
        'callsign' => 'MILE-AIR',
        'country' => 'Updated States',
        'type' => 'airline'
      }
    end

    context 'when the airline is updated successfully' do
      before do
        allow(AIRLINE_COLLECTION).to receive(:upsert).with(airline_id, airline_params)
        allow(Airline).to receive(:find).with(airline_id).and_return(Airline.new(airline_params))
      end

      it 'returns the updated airline' do
        put "/api/v1/airlines/#{airline_id}", params: { airline: airline_params }

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json; charset=utf-8')
        expect(JSON.parse(response.body)).to include(airline_params)
      end
    end

    context 'when the airline does not exist' do
      before do
        allow(AIRLINE_COLLECTION).to receive(:upsert).with(airline_id, airline_params).and_raise(Couchbase::Error::DocumentNotFound)
      end

      it 'returns a not found error' do
        put "/api/v1/airlines/#{airline_id}", params: { airline: airline_params }

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)).to eq({ 'error' => 'Airline not found' })
      end
    end
  end

  describe 'DELETE /api/v1/airlines/{id}' do
    let(:airline_id) { 'airline_delete' }

    context 'when the airline is deleted successfully' do
      before do
        allow(AIRLINE_COLLECTION).to receive(:remove).with(airline_id)
      end

      it 'returns a success message' do
        delete "/api/v1/airlines/#{airline_id}"

        expect(response).to have_http_status(:accepted)
        expect(JSON.parse(response.body)).to eq({ 'message' => 'Airline deleted successfully' })
      end
    end

    context 'when the airline does not exist' do
      before do
        allow(AIRLINE_COLLECTION).to receive(:remove).with(airline_id).and_raise(Couchbase::Error::DocumentNotFound)
      end

      it 'returns a not found error' do
        delete "/api/v1/airlines/#{airline_id}"

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)).to eq({ 'error' => 'Airline not found' })
      end
    end
  end

  describe 'GET /api/v1/airlines/list' do
    let(:country) { 'United States' }
    let(:limit) { 10 }
    let(:offset) { 0 }
    let(:expected_airlines) do
      [
        {
          'callsign' => 'MILE-AIR',
          'country' => 'United States',
          'iata' => 'Q5',
          'icao' => 'MLA',
          'id' => 10,
          'name' => '40-Mile Air',
          'type' => 'airline'
        },
        {
          'callsign' => 'TXW',
          'country' => 'United States',
          'iata' => 'TQ',
          'icao' => 'TXW',
          'id' => 10123,
          'name' => 'Texas Wings',
          'type' => 'airline'
        },
        {
          'callsign' => 'atifly',
          'country' => 'United States',
          'iata' => 'A1',
          'icao' => 'A1F',
          'id' => 10226,
          'name' => 'Atifly',
          'type' => 'airline'
        }
      ]
    end

    before do
      allow(Airline).to receive(:all).with(country, limit, offset).and_return(expected_airlines)
    end

    it 'returns a list of airlines for a given country' do
      get '/api/v1/airlines/list', params: { country: country, limit: limit, offset: offset }

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq('application/json; charset=utf-8')
      expect(JSON.parse(response.body)).to eq(expected_airlines)
    end
  end

  describe 'GET /api/v1/airlines/to-airport' do
    let(:destination_airport_code) { 'MRS' }
    let(:limit) { 10 }
    let(:offset) { 0 }
    let(:expected_airlines) do
      [
        {
          'callsign' => 'AIRFRANS',
          'country' => 'France',
          'iata' => 'AF',
          'icao' => 'AFR',
          'id' => 137,
          'name' => 'Air France',
          'type' => 'airline'
        },
        {
          'callsign' => 'SPEEDBIRD',
          'country' => 'United Kingdom',
          'iata' => 'BA',
          'icao' => 'BAW',
          'id' => 1355,
          'name' => 'British Airways',
          'type' => 'airline'
        },
        {
          'callsign' => 'AIRLINAIR',
          'country' => 'France',
          'iata' => 'A5',
          'icao' => 'RLA',
          'id' => 1203,
          'name' => 'Airlinair',
          'type' => 'airline'
        },
        {
          'callsign' => 'STARWAY',
          'country' => 'France',
          'iata' => 'SE',
          'icao' => 'SEU',
          'id' => 5479,
          'name' => 'XL Airways France',
          'type' => 'airline'
        },
        {
          'callsign' => 'TWINJET',
          'country' => 'France',
          'iata' => 'T7',
          'icao' => 'TJT',
          'id' => 4965,
          'name' => 'Twin Jet',
          'type' => 'airline'
        },
        {
          'callsign' => 'EASY',
          'country' => 'United Kingdom',
          'iata' => 'U2',
          'icao' => 'EZY',
          'id' => 2297,
          'name' => 'easyJet',
          'type' => 'airline'
        },
        {
          'callsign' => 'AMERICAN',
          'country' => 'United States',
          'iata' => 'AA',
          'icao' => 'AAL',
          'id' => 24,
          'name' => 'American Airlines',
          'type' => 'airline'
        },
        {
          'callsign' => 'CORSICA',
          'country' => 'France',
          'iata' => 'XK',
          'icao' => 'CCM',
          'id' => 1909,
          'name' => 'Corse-Mediterranee',
          'type' => 'airline'
        }
      ]
    end

    before do
      allow(Airline).to receive(:to_airport).with(destination_airport_code, limit, offset).and_return(expected_airlines)
    end

    context 'when destinationAirportCode is provided' do
      it 'returns a list of airlines flying to the destination airport' do
        get '/api/v1/airlines/to-airport', params: { destinationAirportCode: destination_airport_code, limit: limit, offset: offset }

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json; charset=utf-8')
        expect(JSON.parse(response.body)).to eq(expected_airlines)
      end
    end

    context 'when destinationAirportCode is not provided' do
      it 'returns a bad request error' do
        get '/api/v1/airlines/to-airport', params: { limit: limit, offset: offset }

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)).to eq({ 'message' => 'Destination airport code is required' })
      end
    end
  end
end

describe 'Airlines API', type: :request  do
  path '/api/v1/airlines/{id}' do
    get 'Retrieves an airline by ID' do
      tags 'Airlines'
      produces 'application/json'
      parameter name: :id, in: :path, type: :string, description: 'ID of the airline'

      response '200', 'airline found' do
        schema type: :object,
          properties: {
            id: { type: :integer },
            name: { type: :string },
            iata: { type: :string },
            icao: { type: :string },
            callsign: { type: :string },
            country: { type: :string }
          },
          required: ['id', 'name', 'iata', 'icao', 'callsign', 'country']

        let(:id) { 'airline_10' }
        run_test!
      end

      response '404', 'airline not found' do
        let(:id) { 'invalid_id' }
        run_test!
      end
    end

    post 'Creates an airline' do
      tags 'Airlines'
      consumes 'application/json'
      parameter name: :airline, in: :body, schema: {
        type: :object,
        properties: {
          id: { type: :integer },
          name: { type: :string },
          iata: { type: :string },
          icao: { type: :string },
          callsign: { type: :string },
          country: { type: :string }
        },
        required: ['id', 'name', 'iata', 'icao', 'callsign', 'country']
      }

      response '201', 'airline created' do
        let(:airline) { { id: 1, name: 'Foo Airlines', iata: 'FA', icao: 'FOO', callsign: 'FOO', country: 'US' } }
        run_test!
      end

      response '422', 'invalid request' do
        let(:airline) { { name: 'Foo Airlines' } }
        run_test!
      end
    end

    put 'Updates an airline' do
      tags 'Airlines'
      consumes 'application/json'
      parameter name: :id, in: :path, type: :string, description: 'ID of the airline'
      parameter name: :airline, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          iata: { type: :string },
          icao: { type: :string },
          callsign: { type: :string },
          country: { type: :string }
        }
      }

      response '200', 'airline updated' do
        let(:id) { 'airline_10' }
        let(:airline) { { name: 'Updated Airline' } }
        run_test!
      end

      response '404', 'airline not found' do
        let(:id) { 'invalid_id' }
        let(:airline) { { name: 'Updated Airline' } }
        run_test!
      end
    end

    delete 'Deletes an airline' do
      tags 'Airlines'
      parameter name: :id, in: :path, type: :string, description: 'ID of the airline'

      response '204', 'airline deleted' do
        let(:id) { 'airline_10' }
        run_test!
      end

      response '404', 'airline not found' do
        let(:id) { 'invalid_id' }
        run_test!
      end
    end
  end

  path '/api/v1/airlines/list' do
    get 'Retrieves all airlines by country' do
      tags 'Airlines'
      produces 'application/json'
      parameter name: :country, in: :query, type: :string, description: 'Country of the airline'
      parameter name: :limit, in: :query, type: :integer, description: 'Maximum number of results to return'
      parameter name: :offset, in: :query, type: :integer, description: 'Number of results to skip for pagination'

      response '200', 'airlines found' do
        schema type: :array,
          items: {
            type: :object,
            properties: {
              id: { type: :integer },
              name: { type: :string },
              iata: { type: :string },
              icao: { type: :string },
              callsign: { type: :string },
              country: { type: :string }
            },
            required: ['id', 'name', 'iata', 'icao', 'callsign', 'country']
          }

        let(:country) { 'United States' }
        let(:limit) { 10 }
        let(:offset) { 0 }
        run_test!
      end
    end
  end

  path '/api/v1/airlines/to-airport' do
    get 'Retrieves airlines flying to a destination airport' do
      tags 'Airlines'
      produces 'application/json'
      parameter name: :destinationAirportCode, in: :query, type: :string, description: 'The ICAO or IATA code of the destination airport'
      parameter name: :limit, in: :query, type: :integer, description: 'Maximum number of results to return'
      parameter name: :offset, in: :query, type: :integer, description: 'Number of results to skip for pagination'

      response '200', 'airlines found' do
        schema type: :array,
          items: {
            type: :object,
            properties: {
              id: { type: :integer },
              name: { type: :string },
              iata: { type: :string },
              icao: { type: :string },
              callsign: { type: :string },
              country: { type: :string }
            },
            required: ['id', 'name', 'iata', 'icao', 'callsign', 'country']
          }

        let(:destinationAirportCode) { 'LAX' }
        let(:limit) { 10 }
        let(:offset) { 0 }
        run_test!
      end

      response '400', 'bad request' do
        let(:destinationAirportCode) { '' }
        run_test!
      end
    end
  end
end
