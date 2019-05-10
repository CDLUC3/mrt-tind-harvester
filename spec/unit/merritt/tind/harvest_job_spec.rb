require 'spec_helper'

module Merritt::TIND
  describe HarvestJob do
    describe :from_config_file do
      it 'creates a harvest job' do
        job = HarvestJob.from_config_file('spec/data/tind-harvester-config.yml')
        expect(job).not_to(be_nil)
      end
    end
  end
end
