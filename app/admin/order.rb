ActiveAdmin.register Order do
  permit_params :order, :status
  decorate_with OrderDecorator

  after_save do |order|
    event = params[:order][:active_admin_requested_event]
    unless event.blank?
      # whitelist to ensure we don't run an arbitrary method
      safe_event = (order.aasm.events(permitted: true).map(&:name) & [event.to_sym]).first
      raise "Forbidden event #{event} requested on instance #{order.id}" unless safe_event
      # launch the event with bang
      order.send("#{safe_event}!")
    end
  end

  index do
    selectable_column
    id_column
    column :user do |o| o.user end
    state_column :status
    column :completed_date
    column :delivery
    column :created_at
    actions
  end

  show do
    attributes_table do
      state_row :status
      row :user
      row :completed_date
      row :delivery
      row :created_at
      row :billing_address do |o|
        o.billing_address
      end
      row :shipping_address do |o|
        o.shipping_address
      end
      row :credit_card
      row :total
    end
  end

  form do |f|
    f.inputs "Order Details" do
      # display current state as disabled to avoid modifying it directly
      f.input :status, input_html: { disabled: true }, label: 'Current state'

      unless f.object.in_progress? || f.object.cancelled?
        # use the attr_accessor to pass the data
        f.input :active_admin_requested_event, label: 'Change state', as: :select, collection: f.object.aasm.events(permitted: true).map(&:name)
      end

    end
    f.actions
  end
end