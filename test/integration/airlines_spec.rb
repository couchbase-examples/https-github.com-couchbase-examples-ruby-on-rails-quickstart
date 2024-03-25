require 'rails_helper'

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
        'country' => 'United States'
      }
    end

    # before do
    #   allow(AIRLINE_COLLECTION).to receive(:get).with(airline_id).and_return(double(success?: true, content: expected_airline))
    # end

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
        'country' => 'United States'
      }
    end

    context 'when the airline is created successfully' do
      # before do
      #   allow(AIRLINE_COLLECTION).to receive(:insert).with(airline_id, airline_params).and_return(true)
      # end

      it 'returns the created airline' do
        post "/api/v1/airlines/#{airline_id}", params: { airline: airline_params }

        expect(response).to have_http_status(:created)
        expect(response.content_type).to eq('application/json; charset=utf-8')
        expect(JSON.parse(response.body)).to include(airline_params.merge('id' => airline_id))
      end
    end

    context 'when the airline already exists' do
      # before do
      #   allow(AIRLINE_COLLECTION).to receive(:insert).with(airline_id, airline_params).and_raise(Couchbase::Error::DocumentExists)
      # end

      it 'returns a conflict error' do
        post "/api/v1/airlines/#{airline_id}", params: { airline: airline_params }

        expect(response).to have_http_status(:conflict)
        expect(JSON.parse(response.body)).to eq({ 'error' => "Airline with ID #{airline_id} already exists" })
      end
    end
  end

  describe 'PUT /api/v1/airlines/{id}' do
    let(:airline_id) { '11' }
    let(:airline_params) do
      {
        'name' => '40-Mile Air',
        'iata' => 'U5',
        'icao' => 'UPD',
        'callsign' => 'MILE-AIR',
        'country' => 'Updated States'
      }
    end

    context 'when the airline is updated successfully' do
      let(:updated_airline) { airline_params.merge('id' => airline_id.to_i) }

      # before do
      #   allow(AIRLINE_COLLECTION).to receive(:upsert).with(airline_id, updated_airline)
      #   allow(Airline).to receive(:find).with(airline_id).and_return(Airline.new(updated_airline))
      # end

      it 'returns the updated airline' do
        put "/api/v1/airlines/#{airline_id}", params: { airline: airline_params }

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json; charset=utf-8')
        expect(JSON.parse(response.body)).to include(airline_params)
      end
    end

    context 'when the airline does not exist' do
      # before do
      #   allow(Airline).to receive(:find).with(airline_id).and_return(nil)
      # end

      it 'returns a not found error' do
        put "/api/v1/airlines/invalid_id", params: { airline: airline_params }
    
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)).to eq({ 'error' => 'Airline with ID invalid_id not found' })
      end
    end
  end

  # describe 'DELETE /api/v1/airlines/{id}' do
  #   let(:airline_id) { 'airline_delete' }

  #   context 'when the airline is deleted successfully' do
  #     before do
  #       allow(Airline).to receive(:find).with(airline_id).and_return(double(destroy: true))
  #     end

  #     it 'returns a success message' do
  #       delete "/api/v1/airlines/#{airline_id}"

  #       expect(response).to have_http_status(:accepted)
  #       expect(JSON.parse(response.body)).to eq({ 'message' => 'Airline deleted successfully' })
  #     end
  #   end

  #   context 'when the airline does not exist' do
  #     before do
  #       allow(Airline).to receive(:find).with(airline_id).and_return(nil)
  #     end

  #     it 'returns a not found error' do
  #       delete "/api/v1/airlines/#{airline_id}"

  #       expect(response).to have_http_status(:not_found)
  #       expect(JSON.parse(response.body)).to eq({ 'error' => 'Airline not found' })
  #     end
  #   end
  # end

  # describe 'GET /api/v1/airlines/list' do
  #   let(:country) { 'United States' }
  #   let(:limit) { '10' }
  #   let(:offset) { '0' }
  #   let(:expected_airlines) do
  #     [
  #       {
  #         'callsign' => 'MILE-AIR',
  #         'country' => 'United States',
  #         'iata' => 'Q5',
  #         'icao' => 'MLA',
  #         'id' => 10,
  #         'name' => '40-Mile Air'
  #       },
  #       {
  #         'callsign' => 'TXW',
  #         'country' => 'United States',
  #         'iata' => 'TQ',
  #         'icao' => 'TXW',
  #         'id' => 10123,
  #         'name' => 'Texas Wings'
  #       },
  #       {
  #         'callsign' => 'atifly',
  #         'country' => 'United States',
  #         'iata' => 'A1',
  #         'icao' => 'A1F',
  #         'id' => 10226,
  #         'name' => 'Atifly'
  #       }
  #     ]
  #   end

  #   before do
  #     allow(Airline).to receive(:all).with(country, limit.to_i, offset.to_i).and_return(expected_airlines)
  #   end

  #   it 'returns a list of airlines for a given country' do
  #     get '/api/v1/airlines/list', params: { country: country, limit: limit, offset: offset }

  #     expect(response).to have_http_status(:ok)
  #     expect(response.content_type).to eq('application/json; charset=utf-8')
  #     expect(JSON.parse(response.body)).to eq(expected_airlines)
  #   end
  # end

  # describe 'GET /api/v1/airlines/to-airport' do
  #   let(:destination_airport_code) { 'MRS' }
  #   let(:limit) { '10' }
  #   let(:offset) { '0' }
  #   let(:expected_airlines) do
  #     [
  #       {
  #         'callsign' => 'AIRFRANS',
  #         'country' => 'France',
  #         'iata' => 'AF',
  #         'icao' => 'AFR',
  #         'id' => 137,
  #         'name' => 'Air France'
  #       },
  #       {
  #         'callsign' => 'SPEEDBIRD',
  #         'country' => 'United Kingdom',
  #         'iata' => 'BA',
  #         'icao' => 'BAW',
  #         'id' => 1355,
  #         'name' => 'British Airways'
  #       },
  #       {
  #         'callsign' => 'AIRLINAIR',
  #         'country' => 'France',
  #         'iata' => 'A5',
  #         'icao' => 'RLA',
  #         'id' => 1203,
  #         'name' => 'Airlinair'
  #       },
  #       {
  #         'callsign' => 'STARWAY',
  #         'country' => 'France',
  #         'iata' => 'SE',
  #         'icao' => 'SEU',
  #         'id' => 5479,
  #         'name' => 'XL Airways France'
  #       },
  #       {
  #         'callsign' => 'TWINJET',
  #         'country' => 'France',
  #         'iata' => 'T7',
  #         'icao' => 'TJT',
  #         'id' => 4965,
  #         'name' => 'Twin Jet'
  #       },
  #       {
  #         'callsign' => 'EASY',
  #         'country' => 'United Kingdom',
  #         'iata' => 'U2',
  #         'icao' => 'EZY',
  #         'id' => 2297,
  #         'name' => 'easyJet'
  #       },
  #       {
  #         'callsign' => 'AMERICAN',
  #         'country' => 'United States',
  #         'iata' => 'AA',
  #         'icao' => 'AAL',
  #         'id' => 24,
  #         'name' => 'American Airlines'
  #       },
  #       {
  #         'callsign' => 'CORSICA',
  #         'country' => 'France',
  #         'iata' => 'XK',
  #         'icao' => 'CCM',
  #         'id' => 1909,
  #         'name' => 'Corse-Mediterranee'
  #       }
  #     ]
  #   end

  #   before do
  #     allow(Airline).to receive(:to_airport).with(destination_airport_code, limit.to_i, offset.to_i).and_return(expected_airlines)
  #   end

  #   context 'when destinationAirportCode is provided' do
  #     it 'returns a list of airlines flying to the destination airport' do
  #       get '/api/v1/airlines/to-airport', params: { destinationAirportCode: destination_airport_code, limit: limit, offset: offset }

  #       expect(response).to have_http_status(:ok)
  #       expect(response.content_type).to eq('application/json; charset=utf-8')
  #       expect(JSON.parse(response.body)).to eq(expected_airlines)
  #     end
  #   end

  #   context 'when destinationAirportCode is not provided' do
  #     it 'returns a bad request error' do
  #       get '/api/v1/airlines/to-airport', params: { limit: limit, offset: offset }

  #       expect(response).to have_http_status(:bad_request)
  #       expect(JSON.parse(response.body)).to eq({ 'message' => 'Destination airport code is required' })
  #     end
  #   end
  # end
end