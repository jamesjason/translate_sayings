require 'rails_helper'

RSpec.describe TextNormalizer do
  describe '#call' do
    context 'basic behavior' do
      it 'returns an empty string for nil input' do
        expect(described_class.new(text: nil).call).to eq('')
      end

      it 'returns an empty string for empty input' do
        expect(described_class.new(text: '').call).to eq('')
      end
    end

    context 'unicode normalization' do
      it 'applies NFKC → NFC normalization' do
        result = described_class.new(text: 'ﬁsh').call
        expect(result).to eq('fish')
      end

      it 'converts full-width characters to half-width' do
        result = described_class.new(text: 'ＡＢＣ').call
        expect(result).to eq('abc')
      end
    end

    context 'smart quotes and invisible characters' do
      it 'replaces smart double quotes with ASCII double quotes' do
        result = described_class.new(text: '“hello”').call
        expect(result).to eq('hello')
      end

      it 'replaces smart single quotes with ASCII single quotes' do
        result = described_class.new(text: '‘hello’').call
        expect(result).to eq('hello')
      end

      it 'removes zero-width characters' do
        zero_width = "h\u200Bel\u200Blo"
        result = described_class.new(text: zero_width).call
        expect(result).to eq('hello')
      end
    end

    context 'combining marks' do
      it 'removes diacritic combining marks' do
        result = described_class.new(text: "e\u0301").call
        expect(result).to eq('e')
      end
    end

    context 'semitic language normalization' do
      it 'removes Arabic tatweel (ـ)' do
        result = described_class.new(text: 'عـــربي').call
        expect(result).to eq('عربی')
      end

      it 'removes Arabic diacritics' do
        result = described_class.new(text: 'سَلام').call
        expect(result).to eq('سلام')
      end

      it 'normalizes Arabic letter variants' do
        result = described_class.new(text: 'أإآٱ').call
        expect(result).to eq('اااا')

        result2 = described_class.new(text: 'يىئ').call
        expect(result2).to eq('ییی')
      end

      it 'removes Hebrew diacritics' do
        result = described_class.new(text: 'שָׁלוֹם').call
        expect(result).to eq('שלום')
      end
    end

    context 'whitespace & punctuation normalization' do
      it 'collapses multiple spaces into one' do
        result = described_class.new(text: 'hello    world').call
        expect(result).to eq('hello world')
      end

      it 'strips leading and trailing whitespace' do
        result = described_class.new(text: '   hello world   ').call
        expect(result).to eq('hello world')
      end

      it 'removes leading and trailing punctuation' do
        result = described_class.new(text: '!!!hello world??').call
        expect(result).to eq('hello world')
      end
    end

    context 'case normalization' do
      it 'downcases all characters' do
        result = described_class.new(text: 'HeLLo WoRLD').call
        expect(result).to eq('hello world')
      end
    end
  end
end
