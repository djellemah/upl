RSpec.describe Upl::Extern do
  it 'PL_VARIABLE' do
    described_class::PL_VARIABLE.should ==              (1)
  end

  it 'PL_ATOM' do
    described_class::PL_ATOM.should ==                  (2)
  end

  it 'PL_INTEGER' do
    described_class::PL_INTEGER.should ==               (3)
  end

  it 'PL_RATIONAL' do
    described_class::PL_RATIONAL.should ==                 (4)
  end

  it 'PL_FLOAT' do
    described_class::PL_FLOAT.should ==                 (5)
  end

  it 'PL_STRING' do
    described_class::PL_STRING.should ==                (6)
  end

  it 'PL_TERM' do
    described_class::PL_TERM.should ==                  (7)
  end

  it 'PL_NIL' do
    described_class::PL_NIL.should ==                   (8)
  end

  it 'PL_BLOB' do
    described_class::PL_BLOB.should ==                  (9)
  end

  it 'PL_LIST_PAIR' do
    described_class::PL_LIST_PAIR.should ==             (10)
  end

  it 'PL_FUNCTOR' do
    described_class::PL_FUNCTOR.should ==               (11)
  end

  it 'PL_LIST' do
    described_class::PL_LIST.should ==                  (12)
  end

  it 'PL_CHARS' do
    described_class::PL_CHARS.should ==                 (13)
  end

  it 'PL_POINTER' do
    described_class::PL_POINTER.should ==               (14)
  end

  it 'PL_CODE_LIST' do
    described_class::PL_CODE_LIST.should ==             (15)
  end

  it 'PL_CHAR_LIST' do
    described_class::PL_CHAR_LIST.should ==             (16)
  end

  it 'PL_BOOL' do
    described_class::PL_BOOL.should ==                  (17)
  end

  it 'PL_FUNCTOR_CHARS' do
    described_class::PL_FUNCTOR_CHARS.should ==         (18)
  end

  it 'PL_PREDICATE_INDICATOR' do
    described_class::PL_PREDICATE_INDICATOR.should ==  (19)
  end

  it 'PL_SHORT' do
    described_class::PL_SHORT.should ==                 (20)
  end

  it 'PL_INT' do
    described_class::PL_INT.should ==                   (21)
  end

  it 'PL_LONG' do
    described_class::PL_LONG.should ==                  (22)
  end

  it 'PL_DOUBLE' do
    described_class::PL_DOUBLE.should ==                (23)
  end

  it 'PL_NCHARS' do
    described_class::PL_NCHARS.should ==                (24)
  end

  it 'PL_UTF8_CHARS' do
    described_class::PL_UTF8_CHARS.should ==            (25)
  end

  it 'PL_UTF8_STRING' do
    described_class::PL_UTF8_STRING.should ==           (26)
  end

  it 'PL_INT64' do
    described_class::PL_INT64.should ==                 (27)
  end

  it 'PL_NUTF8_CHARS' do
    described_class::PL_NUTF8_CHARS.should ==           (28)
  end

  it 'PL_NUTF8_CODES' do
    described_class::PL_NUTF8_CODES.should ==           (29)
  end

  it 'PL_NUTF8_STRING' do
    described_class::PL_NUTF8_STRING.should ==          (30)
  end

  it 'PL_NWCHARS' do
    described_class::PL_NWCHARS.should ==               (31)
  end

  it 'PL_NWCODES' do
    described_class::PL_NWCODES.should ==               (32)
  end

  it 'PL_NWSTRING' do
    described_class::PL_NWSTRING.should ==              (33)
  end

  it 'PL_MBCHARS' do
    described_class::PL_MBCHARS.should ==               (34)
  end

  it 'PL_MBCODES' do
    described_class::PL_MBCODES.should ==               (35)
  end

  it 'PL_MBSTRING' do
    described_class::PL_MBSTRING.should ==              (36)
  end

  it 'PL_INTPTR' do
    described_class::PL_INTPTR.should ==                (37)
  end

  it 'PL_CHAR' do
    described_class::PL_CHAR.should ==                  (38)
  end

  it 'PL_CODE' do
    described_class::PL_CODE.should ==                  (39)
  end

  it 'PL_BYTE' do
    described_class::PL_BYTE.should ==                  (40)
  end

  it 'PL_PARTIAL_LIST' do
    described_class::PL_PARTIAL_LIST.should ==          (41)
  end

  it 'PL_CYCLIC_TERM' do
    described_class::PL_CYCLIC_TERM.should ==           (42)
  end

  it 'PL_NOT_A_LIST' do
    described_class::PL_NOT_A_LIST.should ==            (43)
  end

  it 'PL_DICT' do
    described_class::PL_DICT.should ==                  (44)
  end
end
