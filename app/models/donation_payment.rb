class DonationPayment < ApplicationRecord

    belongs_to :coin, required: true
    belongs_to :donation, required: true
    belongs_to :incoming_transaction, required: true

    after_initialize { self.coin ||= donation.coin }

    def confirmed?
      state == "confirmed"
    end

    def try_to_confirm!
      raise "already confirmed" if confirmed?
      if confirmed_transaction?
        self.update(state: "confirmed", block: incoming_transaction.block, confirmed_at: Time.now)
        create_ledger_entry!
      end
    end

    private

    def confirmed_transaction?
      incoming_transaction.confirmed?
    end

end

# == Schema Information
#
# Table name: donation_payments
#
#  id                      :integer          not null, primary key
#  amount                  :decimal(18, 8)
#  block                   :integer
#  confirmed_at            :datetime
#  detected_at             :datetime
#  state                   :string           default("pending")
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  coin_id                 :integer
#  donation_id             :integer
#  incoming_transaction_id :integer
#  tx_id                   :string           not null
#
# Indexes
#
#  index_donation_payments_on_coin_id                  (coin_id)
#  index_donation_payments_on_donation_id              (donation_id)
#  index_donation_payments_on_incoming_transaction_id  (incoming_transaction_id)
#