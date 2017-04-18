require_relative 'puts'

module Error
    def Error.retrieving_asset(asset, code)
        Puts.error "There was an error retrieving the #{asset} from Github. Code: #{code}."
    end

    def Error.creating_asset(asset, code)
        Puts.error "There was an error creating the #{asset} in the new repo. Code: #{code}."
    end

    def Error.asset_exists(asset)
        Puts.warn "The #{asset} creation request failed validation. It may already exist in the new repo."
    end
end



