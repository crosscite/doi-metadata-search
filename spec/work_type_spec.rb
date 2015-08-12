require 'spec_helper'

describe OrcidClaim do
  subject { OrcidClaim.new(nil) }

  context 'Text' do
    it 'Journal Article' do
      work_type = subject.orcid_work_type('Text', 'Journal Article')
      expect(work_type).to eq('journal-article')
    end

    it 'Book' do
      work_type = subject.orcid_work_type('Text', 'Book')
      expect(work_type).to eq('book')
    end

    it 'Working Paper' do
      work_type = subject.orcid_work_type('Text', 'Working Paper')
      expect(work_type).to eq('working-paper')
    end

    it 'no subtype' do
      work_type = subject.orcid_work_type('Text', nil)
      expect(work_type).to eq('other')
    end
  end

  context 'Dataset' do
    it 'DataPackage' do
      work_type = subject.orcid_work_type('Dataset', 'DataPackage')
      expect(work_type).to eq('data-set')
    end

    it 'Supplementary Collection of Datasets' do
      work_type = subject.orcid_work_type('Dataset', 'Supplementary Collection of Datasets')
      expect(work_type).to eq('data-set')
    end

    it 'no subtype' do
      work_type = subject.orcid_work_type('Dataset', nil)
      expect(work_type).to eq('data-set')
    end
  end

  context 'Software' do
    it 'no subtype' do
      work_type = subject.orcid_work_type('Software', nil)
      expect(work_type).to eq('other')
    end
  end
end
