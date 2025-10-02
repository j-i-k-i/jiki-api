class User::JwtToken < ApplicationRecord
  self.table_name = "user_jwt_tokens"

  belongs_to :user

  validates :jti, presence: true, uniqueness: true
  validates :exp, presence: true

  # Clean up expired tokens
  scope :expired, -> { where("exp < ?", Time.current) }
  scope :active, -> { where("exp >= ?", Time.current) }

  # Optional: Extract device information from aud header
  def device_name
    return "Unknown Device" if aud.blank?

    case aud
    when /iPhone/i then "iPhone"
    when /iPad/i then "iPad"
    when /Android/i then "Android"
    when /Windows/i then "Windows PC"
    when /Macintosh/i then "Mac"
    when /Linux/i then "Linux"
    when /Chrome/i then "Chrome Browser"
    when /Firefox/i then "Firefox Browser"
    when /Safari/i then "Safari Browser"
    when /Edge/i then "Edge Browser"
    else
      aud.truncate(50)
    end
  end

  # Optional: Extract browser information
  def browser
    return "Unknown" if aud.blank?

    case aud
    when /Chrome/i then "Chrome"
    when /Firefox/i then "Firefox"
    when /Safari/i then "Safari"
    when /Edge/i then "Edge"
    when /Opera/i then "Opera"
    else "Unknown"
    end
  end

  # Check if token is expired
  def expired?
    exp < Time.current
  end
end
