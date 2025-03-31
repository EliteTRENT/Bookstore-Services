FactoryBot.define do
  factory :book do
    name { Faker::Book.title }              # e.g., "The Great Gatsby"
    author { Faker::Book.author }           # e.g., "F. Scott Fitzgerald"
    mrp { Faker::Number.decimal(l_digits: 2, r_digits: 2) }  # e.g., 20.99
    discounted_price { Faker::Number.decimal(l_digits: 2, r_digits: 2) }  # e.g., 15.99
    quantity { Faker::Number.between(from: 1, to: 100) }  # e.g., 100
    book_details { Faker::Lorem.paragraph }  # e.g., "A story of the fabulously wealthy Jay Gatsby"
    genre { Faker::Book.genre }              # e.g., "Fiction"
    book_image { Faker::Internet.url(host: 'example.com', path: '/book-cover.jpg') }  # e.g., "http://example.com/book-cover.jpg"
    is_deleted { false }

    # Traits for invalid cases
    trait :missing_name do
      name { "" }
    end

    trait :nil_name do
      name { nil }
    end

    trait :missing_author do
      author { "" }
    end

    trait :nil_author do
      author { nil }
    end

    trait :nil_mrp do
      mrp { nil }
    end

    trait :negative_mrp do
      mrp { -5.0 }
    end

    trait :invalid_mrp do
      mrp { "not_a_number" }
    end

    trait :nil_discounted_price do
      discounted_price { nil }
    end

    trait :negative_discounted_price do
      discounted_price { -5.0 }
    end

    trait :invalid_discounted_price do
      discounted_price { "not_a_number" }
    end

    trait :nil_quantity do
      quantity { nil }
    end

    trait :negative_quantity do
      quantity { -1 }
    end

    trait :non_integer_quantity do
      quantity { 5.5 }
    end

    trait :invalid_quantity do
      quantity { "not_a_number" }
    end

    trait :deleted do
      is_deleted { true }
    end
  end
end