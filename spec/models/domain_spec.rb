require 'spec_helper'
require_relative '../../fs_overlay/opt/certs_manager/certs_manager'

RSpec.describe Domain do
  before do
    allow(NAConfig).to receive(:stage).and_return('local')
  end

  context 'only name is given' do
    context 'without delimiter' do
      it 'returns correct name, upstream and stage' do
        domain = Domain.new('example.com')

        aggregate_failures do
          expect(domain.name).to eq 'example.com'
          expect(domain.upstream).to be_nil
          expect(domain.stage).to eq 'local'
        end
      end
    end

    context 'with delimiter' do
      it 'returns correct name, upstream and stage' do
        domain = Domain.new('example.com ->')

        aggregate_failures do
          expect(domain.name).to eq 'example.com'
          expect(domain.upstream).to be_nil
          expect(domain.stage).to eq 'local'
        end
      end
    end
  end

  context 'only name and upstream are given' do
    context 'without stage indicator' do
      it 'returns correct name, upstream and stage' do
        domain = Domain.new('example.com -> http://upstream')

        aggregate_failures do
          expect(domain.name).to eq 'example.com'
          expect(domain.upstream).to eq 'http://upstream'
          expect(domain.stage).to eq 'local'
        end
      end
    end

    context 'with stage indicator' do
      it 'returns correct name, upstream and stage' do
        domain = Domain.new('example.com -> http://upstream #')

        aggregate_failures do
          expect(domain.name).to eq 'example.com'
          expect(domain.upstream).to eq 'http://upstream'
          expect(domain.stage).to eq 'local'
        end
      end
    end

    context 'with stage indicator and an extra space' do
      it 'returns correct name, upstream and stage' do
        domain = Domain.new('example.com -> http://upstream  #')

        aggregate_failures do
          expect(domain.name).to eq 'example.com'
          expect(domain.upstream).to eq 'http://upstream'
          expect(domain.stage).to eq 'local'
        end
      end
    end
  end

  context 'only name and stage indicator are given' do
    context 'with upstream delimiter' do
      it 'returns correct name, upstream and stage' do
        domain = Domain.new('example.com ->  #staging')

        aggregate_failures do
          expect(domain.name).to eq 'example.com'
          expect(domain.upstream).to be_nil
          expect(domain.stage).to eq 'staging'
        end
      end
    end

    context 'without upstream delimiter' do
      it 'returns correct name, upstream and stage' do
        domain = Domain.new('example.com #staging')

        aggregate_failures do
          expect(domain.name).to eq 'example.com'
          expect(domain.upstream).to be_nil
          expect(domain.stage).to eq 'staging'
        end
      end
    end
  end

  context 'name, upstream and stage are all given' do
    context 'with a space between -> and upstream' do
      it 'returns correct name, upstream and stage' do
        domain = Domain.new('example.com -> http://upstream #staging')

        aggregate_failures do
          expect(domain.name).to eq 'example.com'
          expect(domain.upstream).to eq 'http://upstream'
          expect(domain.stage).to eq 'staging'
        end
      end
    end

    context 'without a space between -> and upstream' do
      it 'returns correct name, upstream and stage' do
        domain = Domain.new('example.com->http://upstream #staging')

        aggregate_failures do
          expect(domain.name).to eq 'example.com'
          expect(domain.upstream).to eq 'http://upstream'
          expect(domain.stage).to eq 'staging'
        end
      end
    end
  end
end


