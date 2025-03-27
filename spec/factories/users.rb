FactoryBot.define do
  factory :user do
    name { "#{Faker::Name.first_name.gsub(/[^a-zA-Z]/, '')} #{Faker::Name.last_name.gsub(/[^a-zA-Z]/, '')}" }  # e.g., "Rahul Gupta"
    email { "#{Faker::Internet.unique.user_name}@gmail.com" }       # e.g., "rahul.gupta123@gmail.com"
    password { "Password@123" }
    mobile_number { "9#{Faker::Number.number(digits: 9)}" }         # e.g., "9876543210"
  end
end
