FactoryGirl.define do

  factory :user do
    skip_create

    name "Josiah Carberry"
    uid "123"
  end

  factory :claim do
    skip_create

    work 1
  end
end
