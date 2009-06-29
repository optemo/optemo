class CreateBestBuyPhones < ActiveRecord::Migration
  def self.up
    create_table :best_buy_phones do |t|
      #Basics
      t.string :title
      t.string :description
      t.string :link
      t.string :category
      t.string :guid
      
      t.string :CategoryID 
      t.string :Manufacturer 
      t.string :ProvinceCode
      t.string :ImageUrl
      t.string :LongDescription 
      t.string :CatGroup
      t.string :CatDept
      t.string :CatClass
      t.string :CatSubClass
      t.string :Price
      #Atts
      t.string :BacklitKeypad
      t.string :BatteryType
      t.string :CPUSpeed
      t.string :Calculator
      t.string :Calendar
      t.string :Carrier
      t.string :ChangeableFaceplateCapable
      t.string :ConnectionPort
      t.string :CustomizableRingTones
      t.string :DataCapabilities
      t.string :DisplayType
      t.string :ExpansionSlots
      t.string :Extras
      t.string :FlashUpgradeable
      t.string :Games
      t.string :HandsfreeSpeakerphone
      t.string :IncludedInBox
      t.string :KeyboardType
      t.string :KeypadLock
      t.string :MP3Capable
      t.string :MemorySize
      t.string :MfrPartNumber
      t.string :ModemType
      t.string :NumberofDisplayLines
      t.string :NumberofModes
      t.string :OperatingSystem
      t.string :OperatingSystemCompatibility
      t.string :OrderConditions
      t.string :PhoneBookCapacity
      t.string :ProductDimensions
      t.string :ProductWarranty
      t.string :ProductWeight
      t.string :ROMSize
      t.string :Resolution
      t.string :Spreadsheet
      t.string :StandbyTime
      t.string :StylusEntry
      t.string :SupportsCallerID
      t.string :TalkTime
      t.string :VibrateMode
      t.string :VoiceRecording
      t.string :WebBrowser
      t.string :WebCode
      t.string :WordProcessor
      
      t.timestamps
    end
  end

  def self.down
    drop_table :best_buy_phones
  end
end
