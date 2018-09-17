require 'fiddle'
require 'fiddle/import'
require 'pathname'

module Upl
  module Extern
    extend Fiddle::Importer

    # use swipl config to find the .so file
    def self.so_path
      begin
        swipl_exe = 'swipl'
        values = `#{swipl_exe} --dump-runtime-variables=sh`.each_line.with_object Hash.new do |line,ha|
          line.chomp!
          # split by = and for rhs strip surrounding quotes and trailing ;
          line =~ /^([^=]+)="([^"]*)";$/
          ha[$1] = $2.strip
        end
      rescue Errno::ENOENT => ex
        puts "#{swipl_exe} not found on path #{ENV['PATH']}"
        exit 1
      end

      begin
        # should result in something like
        #   /usr/lib64/swipl-7.7.18/lib/x86_64-linux/libswipl.so
        # which should actually exist
        p = Pathname "#{values['PLBASE']}/lib/#{values['PLARCH']}/#{values['PLLIB'].gsub('-l', 'lib')}.#{values['PLSOEXT']}"
        p.realpath.to_s
      rescue Errno::ENOENT => ex
        puts "problem with library #{p.to_s}: #{ex.message}"
        exit 1
      end
    end

    dlload so_path

    NULL = Fiddle::Pointer.new 0

    typealias 'term_t', 'void *'
    typealias 'module_t', 'void *'
    typealias 'predicate_t', 'void *'
    typealias 'atom_t', 'void *'
    typealias 'qid_t', 'void *'
    typealias 'fid_t', 'uintptr_t'
    typealias 'functor_t', 'void *'

    extern 'int PL_initialise(int argc, char **argv)'
    extern 'int PL_halt(int status)'

    # for constructing types see https://stackoverflow.com/questions/30293406/is-it-possible-to-use-fiddle-to-pass-or-return-a-struct-to-native-code
    # Predicate_t = struct ['char *data','char *more_data','size_t len']

    # terms
    extern 'predicate_t PL_predicate(const char *name, int arity, const char *module)'

    ##############
    # querying and getting results

    # copied from SWI-Prolog.h
    module Flags
      PL_Q_DEBUG =           0x0001  # = TRUE for backward compatibility
      PL_Q_NORMAL =          0x0002  # normal usage
      PL_Q_NODEBUG =         0x0004  # use this one
      PL_Q_CATCH_EXCEPTION = 0x0008  # handle exceptions in C
      PL_Q_PASS_EXCEPTION =  0x0010  # pass to parent environment
      PL_Q_ALLOW_YIELD =     0x0020  # Support I_YIELD
      PL_Q_EXT_STATUS =      0x0040  # Return extended status
      PL_Q_DETERMINISTIC =   0x0100  # call was deterministic
    end

    extern 'fid_t PL_open_foreign_frame(void)'
    extern 'void PL_rewind_foreign_frame(fid_t cid)'
    extern 'void PL_close_foreign_frame(fid_t cid)'
    extern 'void PL_discard_foreign_frame(fid_t cid)'

    PL_VARIABLE =              (1)
    PL_ATOM =                  (2)
    PL_INTEGER =               (3)
    PL_FLOAT =                 (4)
    PL_STRING =                (5)
    PL_TERM =                  (6)
    PL_NIL =                   (7)
    PL_BLOB =                  (8)
    PL_LIST_PAIR =             (9)
    PL_FUNCTOR =               (10)
    PL_LIST =                  (11)
    PL_CHARS =                 (12)
    PL_POINTER =               (13)
    PL_CODE_LIST =             (14)
    PL_CHAR_LIST =             (15)
    PL_BOOL =                  (16)
    PL_FUNCTOR_CHARS =         (17)
    _PL_PREDICATE_INDICATOR =  (18)
    PL_SHORT =                 (19)
    PL_INT =                   (20)
    PL_LONG =                  (21)
    PL_DOUBLE =                (22)
    PL_NCHARS =                (23)
    PL_UTF8_CHARS =            (24)
    PL_UTF8_STRING =           (25)
    PL_INT64 =                 (26)
    PL_NUTF8_CHARS =           (27)
    PL_NUTF8_CODES =           (29)
    PL_NUTF8_STRING =          (30)
    PL_NWCHARS =               (31)
    PL_NWCODES =               (32)
    PL_NWSTRING =              (33)
    PL_MBCHARS =               (34)
    PL_MBCODES =               (35)
    PL_MBSTRING =              (36)
    PL_INTPTR =                (37)
    PL_CHAR =                  (38)
    PL_CODE =                  (39)
    PL_BYTE =                  (40)
    PL_PARTIAL_LIST =          (41)
    PL_CYCLIC_TERM =           (42)
    PL_NOT_A_LIST =            (43)
    PL_DICT =                  (44)

    module Convert
      REP_UTF8  = 0x1000
      BUF_MALLOC = 0x0200

      CVT_ATOM =            0x0001
      CVT_STRING =          0x0002
      CVT_LIST =            0x0004
      CVT_INTEGER =         0x0008
      CVT_FLOAT =           0x0010
      CVT_VARIABLE =        0x0020
      CVT_NUMBER =          CVT_INTEGER|CVT_FLOAT
      CVT_ATOMIC =          CVT_NUMBER|CVT_ATOM|CVT_STRING
      CVT_WRITE =           0x0040
      CVT_WRITE_CANONICAL = 0x0080
      CVT_WRITEQ =          0x00C0
      CVT_ALL =             CVT_ATOMIC|CVT_LIST
    end

    extern 'predicate_t PL_pred(functor_t f, module_t m)'

    # ctx can be NULL, p is the predicate with arity, t0 is the collection of terms to be filled by the query
    extern 'qid_t PL_open_query(module_t ctx, int pl_q_flags, predicate_t p, term_t t0)'
    extern 'int PL_next_solution(qid_t qid)'
    extern 'void PL_cut_query(qid_t qid)'
    extern 'void PL_close_query(qid_t qid)'

    # shortcut when there will only be one answer
    extern 'int PL_call_predicate(module_t m, int pl_q_flags, predicate_t p, term_t t0)'

    extern 'term_t PL_exception(qid_t qid)'
    extern 'int PL_raise_exception(term_t exception)'
    extern 'int PL_throw(term_t exception)'
    extern 'void PL_clear_exception(void)'

    # qid_t PL_current_query(void)

    # module can be NULL
    extern 'int PL_call(term_t t, module_t m)'

    ####################
    # storage of db records. Not sure if it's useful
    # http://www.swi-prolog.org/pldoc/man?section=foreign-misc
    # void PL_erase(record_t record)
    # record_t PL_record(term_t +t)

    # create empty term(s)
    extern 'term_t PL_new_term_ref()'
    extern 'term_t PL_new_term_refs(int n)'
    extern 'term_t PL_copy_term_ref(term_t from)'

    extern 'int PL_new_atom(const char *s)'
    extern 'int PL_new_atom_nchars(size_t len, const char *s)'
    extern 'functor_t PL_new_functor(atom_t f, int a)'

    extern 'const char * PL_atom_chars(atom_t a)'
    extern 'int PL_get_atom(term_t t, atom_t * a)'

    # get the type
    extern 'int PL_term_type(term_t t)'
    extern 'int PL_is_variable(term_t t)'
    extern 'int PL_is_ground(term_t t)'
    extern 'int PL_is_atom(term_t t)'
    extern 'int PL_is_integer(term_t t)'
    extern 'int PL_is_string(term_t t)'
    extern 'int PL_is_float(term_t t)'
    extern 'int PL_is_rational(term_t t)'
    extern 'int PL_is_compound(term_t t)'
    extern 'int PL_is_callable(term_t t)'
    extern 'int PL_is_functor(term_t t, functor_t f)'
    extern 'int PL_is_list(term_t t)'
    extern 'int PL_is_pair(term_t t)'
    extern 'int PL_is_atomic(term_t t)'
    extern 'int PL_is_number(term_t t)'
    extern 'int PL_is_acyclic(term_t t)'

    extern 'int PL_put_atom(term_t t, atom_t a)'
    extern 'int PL_put_variable(term_t t)'
    extern 'int PL_put_functor(term_t t, functor_t functor)'
    extern 'int PL_put_term(term_t t1, term_t t2)' # Make t1 point to the same term as t2.

    extern 'int PL_cons_functor_v(term_t h, functor_t fd, term_t a0)'

    extern 'int PL_unify_arg(int index, term_t t, term_t a)' # set index-th arg of t to a

    extern 'int PL_get_atom_chars(term_t t, char **a)'
    extern 'int PL_get_string(term_t t, char **s, size_t *len)'
    extern 'int PL_get_integer(term_t t, int *i)'
    extern 'int PL_get_int64(term_t t, int64_t *i)'
    extern 'int PL_get_float(term_t t, double *f)'
    extern 'int PL_get_chars(term_t t, char **s, unsigned int flags)'
    extern 'int PL_get_name_arity(term_t t, atom_t *name, int *arity)'
    extern 'int PL_get_arg(int index, term_t t, term_t a)'
    extern "int PL_get_blob(term_t t, void **blob, size_t *len, PL_blob_t **type)"

    extern 'int PL_get_functor(term_t t, functor_t *f)'

    extern 'int PL_get_nil(term_t l)'
    extern 'int PL_get_list(term_t l, term_t h, term_t t)'
    extern 'int PL_get_head(term_t l, term_t h)'
    extern 'int PL_get_tail(term_t l, term_t t)'

    extern 'int PL_unify(term_t t1, term_t t2)'

    extern 'int PL_skip_list(term_t list, term_t tail, size_t *len)'

    ##################
    # attributed variables. Don't do what I thought they did.
    extern 'int PL_is_attvar(term_t t)'
    extern 'int PL_get_attr(term_t v, term_t a)'

    ##################
    # memory
    extern 'void PL_free(void *mem)'

    ####################
    # looks like parsing of terms
    # only >= 7.6.0
    # get version, call current_prolog_flag(version_data,swi(M,I,P,E)). Major, mInor, Patch, Extra[]
    # PL_EXPORT(int)  PL_put_term_from_chars(term_t t, int flags, size_t len, const char *s);
    # extern 'int PL_put_term_from_chars(term_t t, int flags, size_t len, const char *s)'

    extern 'int PL_chars_to_term(const char *chars, term_t term)'
    extern 'int PL_wchars_to_term(const pl_wchar_t *chars, term_t term)'

    extern 'void PL_unregister_atom(atom_t a)'
  end
end
