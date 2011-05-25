require 'helper'
require 'perftools'

class TestPerformance < Test::Unit::TestCase

  def setup
    [Person, TvShow, SearchIndex].each do |obj|
      obj.drop
      obj.create_indexes
    end
  end

  should "be able to find 1000 times" do
    p = Person.new
    p.name = "Ben"
    p.visits = 10
    p.interests = ["skydiving","coding","reading","swimming"]
    p.jobs.total = 5
    p.jobs.professional = ["pro","fess","ion","al"]
    p.jobs.volunteer = ["vol","un","teer"]
    p.jobs.internships.high_school = ["one","two","three","four"]
    p.location.city = "San Francisco"
    p.location.demographics.crime_rate = :medium
    p.location.demographics.education_quality = :high
    p.misc = { "a" => "b", "c" => "d", "e" => "f", "g" => "h" }
    1.upto(200) { |i| p.misc["i#{i}"] = "......... #{i} ........." }
    p.insert!

    t1 = Time.now.utc.to_f
    PerfTools::CpuProfiler.start("/tmp/mongoo_test_performance") do
      2000.times do |i|
        Person.find_one(p.id)
      end
    end
    t2 = Time.now.utc.to_f

    out = `pprof.rb --text /tmp/mongoo_test_performance`
    puts out

    puts "Perf: #{t2-t1}"
  end

  should "be able to find with :raw much faster" do
    p = Person.new
    p.name = "Ben"
    p.visits = 10
    p.interests = ["skydiving","coding","reading","swimming"]
    p.jobs.total = 5
    p.jobs.professional = ["pro","fess","ion","al"]
    p.jobs.volunteer = ["vol","un","teer"]
    p.jobs.internships.high_school = ["one","two","three","four"]
    p.location.city = "San Francisco"
    p.location.demographics.crime_rate = :medium
    p.location.demographics.education_quality = :high
    p.misc = { "a" => "b", "c" => "d", "e" => "f", "g" => "h" }
    1.upto(200) { |i| p.misc["i#{i}"] = "......... #{i} ........." }
    p.insert!

    t1 = Time.now.utc.to_f
    PerfTools::CpuProfiler.start("/tmp/mongoo_test_performance") do
      2000.times do |i|
        Person.find_one(p.id, {raw: true})
      end
    end
    t2 = Time.now.utc.to_f

    out = `pprof.rb --text /tmp/mongoo_test_performance`
    puts out

    puts "Perf: #{t2-t1}"
  end
end