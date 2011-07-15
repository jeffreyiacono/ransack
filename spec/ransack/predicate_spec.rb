require 'spec_helper'

module Ransack
  describe Predicate do

    before do
      @s = Search.new(Person)
    end

    describe 'cont' do
      it 'generates a LIKE query with value surrounded by %' do
        @s.name_cont = 'ric'
        @s.result.to_sql.should match /"people"."name" LIKE '%ric%'/
      end
    end

    describe 'not_cont' do
      it 'generates a NOT LIKE query with value surrounded by %' do
        @s.name_not_cont = 'ric'
        @s.result.to_sql.should match /"people"."name" NOT LIKE '%ric%'/
      end
    end

    describe 'null' do
      it 'generates a value IS NULL query' do
        @s.name_null = true
        @s.result.to_sql.should match /"people"."name" IS NULL/
      end
    end

    describe 'not_null' do
      it 'generates a value IS NOT NULL query' do
        @s.name_not_null = true
        @s.result.to_sql.should match /"people"."name" IS NOT NULL/
      end
    end

    describe 'matches' do
      it "generates a value LIKE 't' when true" do
        @s.is_cool_matches = true
        @s.result.to_sql.should match /"people"."is_cool" LIKE 't'/
      end

      it "generates a value LIKE 'f' when false" do
        @s.is_cool_matches = false
        @s.result.to_sql.should match /"people"."is_cool" LIKE 'f'/
      end
    end

    describe 'blank' do
      it "generates a value IS NULL OR ='' when true" do
        @s.name_blank = true
        @s.result.to_sql.should match /"people"."name" IS NULL OR "people"."name" = ''/
      end

      it "generates a value IS NOT NULL OR !='' when false" do
        @s.name_blank = false
        @s.result.to_sql.should match /"people"."name" IS NOT NULL OR "people"."name" != ''/
      end
    end
  end
end
