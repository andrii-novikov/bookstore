class Ability
  include CanCan::Ability

  def initialize(user)
    can [:manage], OrdersItem
    can [:index, :show], Category
    can [:show], Book
    can [:show], User, id: user.id
    can [:create], Review if user.present?
    can [:show, :update, :index, :make_order], Order, user:user
  end
end
