#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require 'spec_helper'

describe Queries::Filters::AvailableFilters, type: :model do
  let(:context) { FactoryBot.build_stubbed(:project) }
  let(:register) { Queries::FilterRegister }

  class HelperClass
    attr_accessor :context

    def initialize(context)
      self.context = context
    end

    include Queries::Filters::AvailableFilters
  end

  let(:includer) do
    includer = HelperClass.new(context)

    allow(Queries::Register)
      .to receive(:filters)
      .and_return(HelperClass => registered_filters)

    includer
  end

  describe '#filter_for' do
    let(:filter1_available) { true }
    let(:filter2_available) { true }
    let(:filter1_key) { :filter1 }
    let(:filter2_key) { /f_\d+/ }
    let(:filter1_name) { :filter1 }
    let(:filter2_name) { :f1 }
    let(:registered_filters) { [filter1, filter_2] }

    let(:filter1_instance) do
      instance = double("filter1_instance") # rubocop:disable Rspec/VerifiedDoubles

      allow(instance)
        .to receive(:available?)
        .and_return(:filter1_available)

      allow(instance)
        .to receive(:name)
        .and_return(filter1_name)

      allow(instance)
        .to receive(:name=)

      instance
    end

    let(:filter1) do
      filter = double('filter1') # rubocop:disable Rspec/VerifiedDoubles

      allow(filter)
        .to receive(:key)
        .and_return(filter1_key)

      allow(filter)
        .to receive(:create!)
        .and_return(filter1_instance)

      allow(filter)
        .to receive(:all_for)
        .with(context)
        .and_return(filter1_instance)

      filter
    end

    let(:filter_2_instance) do
      instance = double("filter_2_instance") # rubocop:disable Rspec/VerifiedDoubles

      allow(instance)
        .to receive(:available?)
        .and_return(filter2_available)

      allow(instance)
        .to receive(:name)
        .and_return(:f1)

      allow(instance)
        .to receive(:name=)

      instance
    end

    let(:filter_2) do
      filter = double('filter_2') # rubocop:disable Rspec/VerifiedDoubles

      allow(filter)
        .to receive(:key)
        .and_return(/f\d+/)

      allow(filter)
        .to receive(:all_for)
        .with(context)
        .and_return(filter_2_instance)

      filter
    end

    context 'for a filter identified by a symbol' do
      let(:filter_3_available) { true }
      let(:registered_filters) { [filter_3, filter1, filter_2] }

      # As we use regexp to find the filters
      # we have to ensure that a filter identified a substring symbol
      # is not accidentally found
      let(:filter_3) do
        instance = double('filter_3_instance')

        allow(instance)
          .to receive(:available?)
          .and_return(filter_3_available)

        filter = double('filter_3')

        allow(filter)
          .to receive(:key)
          .and_return(:filter)

        allow(filter)
          .to receive(:all_for)
          .with(context)
          .and_return(instance)

        filter
      end

      context 'if available' do
        let(:filter_3_available) { false }

        it 'returns an instance of the matching filter' do
          expect(includer.filter_for(:filter1)).to eql filter1_instance
        end

        it 'returns the NotExistingFilter if the name is not matched' do
          expect(includer.filter_for(:not_a_filter_name)).to be_a Queries::Filters::NotExistingFilter
        end
      end

      context 'if not available' do
        let(:filter1_available) { false }
        let(:filter_3_available) { true }

        it 'returns the NotExistingFilter if the name is not matched' do
          expect(includer.filter_for(:not_a_filter_name)).to be_a Queries::Filters::NotExistingFilter
        end

        it 'returns an instance of the matching filter if not caring for availablility' do
          expect(includer.filter_for(:filter1, no_memoization: true)).to eql filter1_instance
        end
      end
    end

    context 'for a filter identified by a regexp' do
      context 'if available' do
        it 'returns an instance of the matching filter' do
          expect(includer.filter_for(:f1)).to eql filter_2_instance
        end

        it 'returns the NotExistingFilter if the key is not matched' do
          expect(includer.filter_for(:fi1)).to be_a Queries::Filters::NotExistingFilter
        end

        it 'returns the NotExistingFilter if the key is matched but the name is not' do
          expect(includer.filter_for(:f2)).to be_a Queries::Filters::NotExistingFilter
        end
      end

      context 'is false if unavailable' do
        let(:filter2_available) { false }

        it 'returns the NotExistingFilter' do
          expect(includer.filter_for(:fi)).to be_a Queries::Filters::NotExistingFilter
        end
      end
    end
  end
end
