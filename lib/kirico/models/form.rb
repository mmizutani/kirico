# frozen_string_literal: true
require 'virtus'
require 'active_model'

module Kirico
  class Form
    include Virtus.model
    include ActiveModel::Validations

    FILE_NAME = 'SHFD0006.CSV'

    attribute :fd, Kirico::BaseFDManagementRecord
    attribute :company_count, Kirico::BaseCompanyCount
    attribute :company, Kirico::Company
    attribute :records, Array[Kirico::ApplicationRecord]

    validates :fd, :company_count, :company, :records, presence: true
    validate :validate_children

    def initialize(fd:, company_count: Kirico::CompanyCount.new, company:, records: [])
      @fd = fd
      @company_count = company_count
      @company = company
      @records = records
    end

    def to_csv
      [
        @fd.to_csv,
        Kirico::CompanyIdentifier.new.to_csv,
        @company_count.to_csv,
        @company.to_csv,
        Kirico::DataIdentifier.new.to_csv,
        @records.map(&:to_csv).join("\r\n"),
        ''
      ].join("\r\n")
    end

    private

    # 子のエラーを自身のエラーとして設定する
    def validate_children
      [:fd, :company, :company_count, :records].each do |attribute|
        records = [send(attribute)].flatten.compact
        records.each do |rec|
          next if rec.valid?
          rec.errors.full_messages.each do |msg|
            errors.add(attribute, msg)
          end
        end
      end
    end
  end
end
