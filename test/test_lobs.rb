require 'test/unit'
require_relative "../lib/simple_record"
require_relative "test_helpers"
require_relative "test_base"
require "yaml"
require 'aws'
require_relative 'my_model'
require_relative 'my_child_model'
require_relative 'model_with_enc'

# Tests for SimpleRecord
#

class TestLobs < TestBase
    def assert_puts(x)
      assert_stat("puts",x)
    end

    def assert_gets(x)
      assert_stat("gets",x)
    end

    def assert_deletes(x)
      assert_stat("deletes",x)
    end

    def assert_stat(stat, x)
      assert eval("SimpleRecord.stats.s3_#{stat} == x"), "#{stat} is #{eval("SimpleRecord.stats.s3_#{stat}")}, should be #{x}."
    end

    def test_prep
      MyModel.delete_domain
    end

    def test_clobs
        mm = MyModel.new

        #puts mm.clob1.inspect
        assert mm.clob1.nil?

        mm.name  = "whatever"
        mm.age   = "1"
        mm.clob1 = "0" * 2000
        assert_puts(0)
        #puts mm.inspect
        mm.save

        assert_puts(1)
        sleep 2

        mm.clob1 = "1" * 2000
        mm.clob2 = "2" * 2000
        mm.save
        assert_puts(3)

        mm2 = MyModel.find(mm.id)
        assert mm.id == mm2.id
        #puts 'mm.clob1=' + mm.clob1.to_s
        #puts 'mm2.clob1=' + mm2.clob1.to_s
        assert mm.clob1 == mm2.clob1
        assert_puts(3)
        assert_gets(1)
        mm2.clob1 # make sure it doesn't do another get
        assert_gets(1)

        assert mm.clob2 == mm2.clob2
        assert_gets(2)

        mm2.save

        # shouldn't save twice if not dirty
        assert_puts(3)

        mm2.delete

        assert_deletes(2)

        e = assert_raise(Aws::AwsError) do
            sclob = SimpleRecord.s3.bucket(mm2.s3_bucket_name2).get(mm2.s3_lob_id("clob1"))
        end
        assert_match(/NoSuchKey/, e.message)
        e = assert_raise(Aws::AwsError) do
            sclob = SimpleRecord.s3.bucket(mm2.s3_bucket_name2).get(mm2.s3_lob_id("clob2"))
        end
        assert_match(/NoSuchKey/, e.message)


    end

    def test_single_clob
        mm = SingleClobClass.new

        #puts mm.clob1.inspect
        assert mm.clob1.nil?

        mm.name  = "whatever"
        mm.clob1 = "0" * 2000
        mm.clob2 = "2" * 2000
        assert_puts(0)
        #puts mm.inspect
        mm.save

        assert_puts(1)

        sleep 2

        mm2 = SingleClobClass.find(mm.id)
        assert mm.id == mm2.id
        #puts 'mm.clob1=' + mm.clob1.to_s
        #puts 'mm2.clob1=' + mm2.clob1.to_s
        assert_equal mm.clob1, mm2.clob1
        assert_puts(1)
        assert_gets(1)
        mm2.clob1 # make sure it doesn't do another get
        assert_gets(1)

        assert mm.clob2 == mm2.clob2
        assert_gets(1)

        mm2.save

        # shouldn't save twice if not dirty
        assert_puts(1)

        mm2.delete

        assert_deletes(1)

        e = assert_raise(Aws::AwsError) do
            sclob = SimpleRecord.s3.bucket(mm2.s3_bucket_name2).get(mm2.single_clob_id)
        end
        assert_match(/NoSuchKey/, e.message)

    end

    def test_cleanup
      MyModel.delete_domain
    end
end
