#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2019 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module OpenProject::Bcf::Patches::AggregatedJournalPatch
  def self.included(base)
    base.class_exec do
      delegate :bcf_comment,
               :bcf_comment=,
               to: :journal
    end

    # base.singleton_class.prepend ClassMethods
    base.prepend InstanceMethods
  end

  module ClassMethods
    def preload_associations(journable, aggregated_journals, includes)
      aggregated_journals = super(journable, aggregated_journals, includes)
      if includes.include?(:bcf_comments)
        bcf_comments = if includes.include?(:bcf_comment)
                         ::Bcf::Comment
                           .where(journal_id: journal_ids)
                           .all
                           .group_by(&:journal_id)
                       end

        aggregated_journals.each do |aggregated_journal|
          # Preload bcf_comment and its viewpoint.
          aggregated_journal.set_preloaded_bcf_comment(bcf_comments[aggregated_journal.id].first)
        end
      end
    end
  end

  module InstanceMethods
    def set_preloaded_bcf_comment(loaded_bcf_comment)
      self.journal.bcf_comment = loaded_bcf_comment
      journal.association(:bcf_comment).loaded!
    end
  end
end
