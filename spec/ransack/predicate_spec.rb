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

    describe 'eq' do
      it "generates a value = 't' when true" do
        @s.is_cool_eq = true
        @s.result.to_sql.should match /"people"."is_cool" = 't'/
      end

      it "generates a value = 'f' when false" do
        @s.is_cool_eq = false
        @s.result.to_sql.should match /"people"."is_cool" = 'f'/
      end
    end
  end
end
