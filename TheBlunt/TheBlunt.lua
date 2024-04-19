--- STEAMODDED HEADER
--- MOD_NAME: The Blunt
--- MOD_ID: SnoresvilleTheBlunt
--- MOD_AUTHOR: [Snoresville]
--- MOD_DESCRIPTION: 420
--- BADGE_COLOUR: 00FF00

----------------------------------------------
------------MOD CODE -------------------------
local MOD_ID = "SnoresvilleTheBlunt"

local jokers = {
    snoresville_the_blunt = {
        name = "The Blunt",
        slug = "snoresville_the_blunt",
        config = {
            extra = {
                chips = 10,
                mult = 1,
                smoked = {},
            }
        },
        spritePos = {x = 0, y = 0},
        loc_txt = {
            name = "The Blunt",
            text = {
                "Unscored cards are fed into {C:green}The Blunt{}.",
                "Add {C:blue}Chips{} and {C:red}Mult{} to cards",
                "scored in {C:attention}High Card{} hands.",
                "{C:inactive}(Currently {C:blue}+#1# Chips{C:inactive} and {C:red}+#2# Mult{C:inactive})"
            }
        },
        rarity = 3,
        cost = 6,
        unlocked = true,
        discovered = true,
        blueprint_compat = true,
        eternal_compat = true,
        functions = {
            loc_def = function(self)
                return {self.ability.extra.chips, self.ability.extra.mult}
            end,
            calculate = function(self, context)
                if context.scoring_name == "High Card" and context.cardarea == G.play and context.individual then
                    return {
                        chips = self.ability.extra.chips,
                        mult = self.ability.extra.mult,
                        card = self
                    }
                end
                if context.cardarea == G.jokers and context.joker_main then
                    for i = 1, #context.full_hand do
                        local card = context.full_hand[i]
                        local destroyed = true

                        for j = 1, #context.scoring_hand do
                            if context.scoring_hand[j] == card then
                                destroyed = false
                                break
                            end
                        end

                        if destroyed then
                            local bonus_chips = card.base.nominal + card.ability.bonus + (card.ability.perma_bonus or 0)
                            local bonus_mult = (self.ability.mult or 0)
                            self.ability.extra.chips = self.ability.extra.chips + bonus_chips
                            self.ability.extra.mult = self.ability.extra.mult + bonus_mult
                            table.insert(self.ability.extra.smoked, card)

                            G.E_MANAGER:add_event(Event({trigger = 'before', delay = 0.5, func = function()
                                if card and not card.shattered and not card.destroyed then
                                    if card.ability.name == 'Glass Card' then
                                        card.shattered = true
                                        card:shatter()
                                    else
                                        card.destroyed = true
                                        card:start_dissolve()
                                    end
                                end
                                return true
                            end}))
                            G.E_MANAGER:add_event(Event({trigger = 'before', delay = 1, func = function()
                                if bonus_chips > 0 then
                                    card_eval_status_text(self, 'chips', bonus_chips, nil, nil, {
                                        instant = true
                                    })
                                end
                                return true
                            end}))
                            G.E_MANAGER:add_event(Event({trigger = 'before', delay = 1, func = function()
                                if bonus_mult > 0 then
                                    card_eval_status_text(self, 'mult', bonus_mult, nil, nil, {
                                        instant = true
                                    })
                                end
                                return true
                            end}))
                        end
                    end
                elseif context.end_of_round then
                    -- This is how cards are permanently removed from the deck with the blunt
                    -- The destroy methods above are not enough
                    if not context.blueprint and not context.repetition then
                        for i = 1, #self.ability.extra.smoked do
                            self.ability.extra.smoked[i]:start_dissolve(nil, true, 0, true)
                        end
                        self.ability.extra.smoked = {}
                    end
                end
            end
        }
    }
}

local function init_modded_jokers()
    local joker_objects = {}

    for joker_id, joker_def in pairs(jokers) do
        joker_objects[joker_id] = SMODS.Joker:new(
            joker_def.name,
            joker_def.slug,
            joker_def.config,
            joker_def.spritePos,
            joker_def.loc_txt,
            joker_def.rarity,
            joker_def.cost,
            joker_def.unlocked,
            joker_def.discovered,
            joker_def.blueprint_compat,
            joker_def.eternal_compat
        )
    end

    -- Order the jokers
    local joker_sorted = {}

    for joker_name, joker_data in pairs(joker_objects) do
        local j = {}
        j.name = joker_data.name
        j.rarity = joker_data.rarity
        j.slug = joker_name
        table.insert(joker_sorted, j)
    end

    table.sort(joker_sorted, function(a, b)
        if a.rarity ~= b.rarity then
            return a.rarity < b.rarity
        end
        return a.name < b.name
    end)

    for _, joker_data in ipairs(joker_sorted) do
        local name = joker_data.slug
        local v = joker_objects[name]

        v.slug = "j_" .. name
        v.mod = MOD_ID
        v:register()

        -- https://github.com/Steamopollys/Steamodded/wiki/Creating-new-game-objects#creating-jokers
        SMODS.Sprite:new(v.slug, SMODS.findModByID(MOD_ID).path, v.slug..".png", 71, 95, "asset_atli")
        :register()
    end

    for joker_id, joker_def in pairs(jokers) do
        local joker_slug = "j_"..joker_id
        for function_name, function_call in pairs(joker_def.functions) do
            SMODS.Jokers[joker_slug][function_name] = function_call
        end
    end
end

function SMODS.INIT.SnoresvilleTheBlunt()
    sendDebugMessage("420")
    init_localization()
    init_modded_jokers()
end