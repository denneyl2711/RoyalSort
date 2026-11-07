-- adapted from MagicSort code --> https://github.com/acidflow-balatro/MagicSort/blob/main/MagicSort/MagicSort.lua

-- TODO(denneyl): move the sorting comments up here?
local DESCENDING_SORT_PRIORITIES = {
    seal = {
        Blue = 1, Purple = 2, Gold = 3, Red = 4,
    },
    suit = {
        Spades = 1, Hearts = 2, Clubs = 3, Diamonds = 4
    },
    rank = {
        Ace = 1,
        King = 2,
        Queen = 3,
        Jack = 4,
        [10] = 5,
        [9] = 6,
        [8] = 7,
        [7] = 8,
        [6] = 9,
        [5] = 10,
        [4] = 11,
        [3] = 12,
        [2] = 13
    },
    enhancement = {
        m_gold = 2,
        m_glass = 3,
        m_wild = 4,
        m_bonus = 5,
        m_mult = 6,
        m_lucky = 7,
        m_steel = 8,
        m_stone = 9,
    },
}

local ASCENDING_SORT_PRIORITIES = {
    seal = {
        Blue = 1, Purple = 2, Gold = 3, Red = 4,
    },
    suit = {
        Spades = 1, Hearts = 2, Clubs = 3, Diamonds = 4
    },
    rank = {
        [2] = 1,
        [3] = 2,
        [4] = 3,
        [5] = 4,
        [6] = 5,
        [7] = 6,
        [8] = 7,
        [9] = 8,
        [10] = 9,
        Jack = 10,
        Queen = 11,
        King = 12,
        Ace = 13,
    },
    enhancement = {
        m_gold = 2,
        m_glass = 3,
        m_wild = 4,
        m_bonus = 5,
        m_mult = 6,
        m_lucky = 7,
        m_steel = 8,
        m_stone = 9,
    },
}

local function get_sort_key(card, is_garbage, is_ascending)
    local SORT_PRIORITIES = is_ascending and ASCENDING_SORT_PRIORITIES or DESCENDING_SORT_PRIORITIES
    local default_val = 000
    local keys = { default_val, default_val, default_val, default_val }

    -- not sure how we get here but this is in the original so whatever
    if not card then
        return string.format("%03d%03d%03d03d", keys[1], keys[2], keys[3], keys[4])
    end

    -- enhancements
    if card.config and card.config.center and card.config.center.key then
        keys[1] = SORT_PRIORITIES.enhancement[card.config.center.key] or default_val
    end

    -- Seal priority mapping
    if card.seal then
        keys[2] = SORT_PRIORITIES.seal[card.seal] or default_val
    end

    -- Rank detection and classification
    if card.base and card.base.id then
        local rank = card.base.id

        if type(rank) == "number" then
            if rank >= 2 and rank <= 10 then
                keys[3] = SORT_PRIORITIES.rank[rank] or default_val
            elseif rank == 11 then
                keys[3] = SORT_PRIORITIES.rank.Jack or default_val
            elseif rank == 12 then
                keys[3] = SORT_PRIORITIES.rank.Queen or default_val
            elseif rank == 13 then
                keys[3] = SORT_PRIORITIES.rank.King or default_val
            elseif rank == 14 then
                keys[3] = SORT_PRIORITIES.rank.Ace or default_val
            end
        elseif type(rank) == "string" then
            keys[3] = SORT_PRIORITIES.rank[rank] or default_val
        end
    end

    -- Suit hierarchy processing
    if card.base and card.base.suit then
        keys[4] = SORT_PRIORITIES.suit[card.base.suit] or default_val
    end

    if is_garbage then
        --return rank, suit, enhance, seal for garbage
        return string.format("%03d%03d%03d03d", keys[3], keys[4], keys[1], keys[2])
    else
        --return enhance, seal, rank, suit for royals
        return string.format("%03d%03d%03d03d", keys[1], keys[2], keys[3], keys[4])
    end
end

local function get_royal_sort(card, is_ascending)
    return get_sort_key(card, false, is_ascending)
end

local function get_garbage_sort(card, is_ascending)
    return get_sort_key(card, true, is_ascending)
end

--here's all the different combos for baron, shoot the moon, and raised fist

-- (none) --------------> sort by rank? maybe just get rid of the button
-- baron ---------------> same as (none)
-- stm *****************> sort by desc. rank, steel cards to the right
-- fist ****************> sort by asc. rank, steel cards to the right
-- baron + stm ---------> queens, kings, garbage
-- baron + fist ********> same as (fist)
-- stm + fist **********> same as (fist)
-- baron + stm + fist **> same as (fist)
--TODO(denneyl): if there's no steel in hand for the starred items, don't do weird sorting
local function create_piles(is_baron, is_shoot_the_moon, is_raised_fist)
    local piles = {}
    local is_ascending = false
    if is_raised_fist then
        is_ascending = true

        local not_steel = {}
        local steel = {}
        local stone = {}

        for _, card in ipairs(G.hand.cards) do
            if card and card.base and card.base.id then
                local sort_key
                local pile
                if card.config and card.config.center and card.config.center.key == "m_stone" then
                    sort_key = get_garbage_sort(card, is_ascending)
                    pile = stone
                else
                    sort_key = get_garbage_sort(card, is_ascending)
                    if card.config and card.config.center and card.config.center.key == "m_steel" then
                        pile = steel
                    else
                        pile = not_steel
                    end
                end

                table.insert(pile, {
                    card = card,
                    key = sort_key
                })
            end
        end

        piles[#piles + 1] = not_steel
        piles[#piles + 1] = steel
        piles[#piles + 1] = stone
    elseif is_baron and is_shoot_the_moon then
        local queens = {}
        local kings = {}
        local garbage = {}

        for _, card in ipairs(G.hand.cards) do
            if card and card.base and card.base.id then
                local sort_key
                local pile
                if card.base.id == 13 then
                    sort_key = get_royal_sort(card, is_ascending)
                    pile = kings
                elseif card.base.id == 12 then
                    sort_key = get_royal_sort(card, is_ascending)
                    pile = queens
                else
                    sort_key = get_garbage_sort(card, is_ascending)
                    pile = garbage
                end

                table.insert(pile, {
                    card = card,
                    key = sort_key
                })
            end
        end

        piles[#piles + 1] = queens
        piles[#piles + 1] = kings
        piles[#piles + 1] = garbage
    elseif is_shoot_the_moon then
        local not_steel_queens = {}
        local steel_queens = {}
        local garbage = {}
        local stone = {}

        for _, card in ipairs(G.hand.cards) do
            if card and card.base and card.base.id then
                local sort_key
                local pile
                if card.config and card.config.center and card.config.center.key == "m_stone" then
                    sort_key = get_garbage_sort(card, is_ascending)
                    pile = stone
                elseif card.base.id == 12 then
                    sort_key = get_royal_sort(card, is_ascending)
                    if card.config and card.config.center and card.config.center.key == "m_steel" then
                        pile = steel_queens
                    else
                        pile = not_steel_queens
                    end
                else
                    sort_key = get_garbage_sort(card, is_ascending)
                    pile = garbage
                end

                table.insert(pile, {
                    card = card,
                    key = sort_key
                })
            end
        end

        piles[#piles + 1] = not_steel_queens
        piles[#piles + 1] = steel_queens
        piles[#piles + 1] = garbage
        piles[#piles + 1] = stone
    else
        local the_pile = {}
        for _, card in ipairs(G.hand.cards) do
            local sort_key = get_garbage_sort(card, is_ascending)
            local pile = the_pile

            table.insert(pile, {
                card = card,
                key = sort_key
            })
        end

        piles[#piles + 1] = the_pile
    end

    return piles
end

-- TODO(denneyl): create an option to not apply royal sort in arcana/spectral packs
local function royal_sort()
    if not G then
        return
    end
    if not G.hand then
        return
    end
    if not G.hand.cards then
        return
    end
    if #G.hand.cards == 0 then
        return
    end

    local is_baron = next(SMODS.find_card('j_baron')) ~= nil
    local is_shoot_the_moon = next(SMODS.find_card('j_shoot_the_moon')) ~= nil
    local is_raised_fist = next(SMODS.find_card('j_raised_fist')) ~= nil

    piles = create_piles(is_baron, is_shoot_the_moon, is_raised_fist)

    -- sort the cards
    for _, pile in ipairs(piles) do
        stable_sort(pile, function(a, b)
            return a.key < b.key
        end)
    end

    -- build our new hand from sorted cards
    local new_cards = {}
    for _, pile in ipairs(piles) do
        for _, item in ipairs(pile) do
            if item and item.card then
                table.insert(new_cards, item.card)
            end
        end
    end

    -- apply sorted cards to the game hand
    if #new_cards == #G.hand.cards then
        G.hand.cards = new_cards
        if G.hand.align_cards then
            G.hand:align_cards()
        end
    end
end

G.FUNCS.ROYAL_SORT = royal_sort

-- Initialize button functionality
G.FUNCS = G.FUNCS or {}
G.FUNCS.royal_sort_hand = function(e)
    -- Apply royal sort configuration
    if G.hand and G.hand.config then
        G.hand.config.sort = 'royal'
        royal_sort()
    end
end

-- UI stuff
local original_create_UIBox_buttons = create_UIBox_buttons

function create_UIBox_buttons()
    local ret = original_create_UIBox_buttons and original_create_UIBox_buttons()

    if not ret then
        return ret
    end

    -- Inject Royal Sort button during hand selection phase
    if G.STATE == G.STATES.SELECTING_HAND and G.hand and #G.hand.cards > 0 then
        local function find_sort_container(node)
            if node.nodes then
                for i, child in ipairs(node.nodes) do
                    if child.nodes then
                        for j, grandchild in ipairs(child.nodes) do
                            if grandchild.config and grandchild.config.button and
                                    (grandchild.config.button == "sort_hand_suit" or grandchild.config.button == "sort_hand_value") then
                                return child
                            end
                        end
                    end
                    local found = find_sort_container(child)
                    if found then
                        return found
                    end
                end
            end
            return nil
        end

        local sort_container = find_sort_container(ret)

        if sort_container and sort_container.nodes then
            -- Create Royal Sort button with consistent styling
            local royal_button = {
                n = G.UIT.C,
                config = {
                    align = "cm",
                    padding = 0.1,
                    r = 0.08,
                    minw = 0.9,
                    minh = 0.4,
                    hover = true,
                    colour = G.C.ORANGE, -- Force orange color always
                    button = "royal_sort_hand",
                    shadow = true
                },
                nodes = {
                    {
                        n = G.UIT.T,
                        config = {
                            text = "Royal",
                            colour = G.C.UI.TEXT_LIGHT,
                            scale = 0.35,
                            shadow = true
                        }
                    }
                }
            }

            table.insert(sort_container.nodes, royal_button)
        else
            -- Fallback Royal Sort interface
            -- TODO(denneyl): what is this doing? Fallback for if there is no sort container?
            -- Like when we draw cards for an arcana pack or something?
            -- that doesn't make sense either...
            if ret.nodes then
                local royal_row = {
                    n = G.UIT.R,
                    config = { align = "cm", padding = 0.1 },
                    nodes = {
                        {
                            n = G.UIT.C,
                            config = {
                                align = "cm",
                                padding = 0.1,
                                r = 0.08,
                                minw = 2.0,
                                minh = 0.6,
                                hover = true,
                                colour = G.C.ORANGE,
                                button = "royal_sort_hand",
                                shadow = true
                            },
                            nodes = {
                                {
                                    n = G.UIT.T,
                                    config = {
                                        text = "ROYAL SORT",
                                        colour = G.C.UI.TEXT_LIGHT,
                                        scale = 0.4,
                                        shadow = true
                                    }
                                }
                            }
                        }
                    }
                }

                table.insert(ret.nodes, royal_row)
            end
        end
    end
    return ret
end

-- this is from Gemini, not my fault if it breaks everything
-- now that I look at it though, this is actually pretty simple :)
function stable_sort(tbl, comp)
    -- Add original index to elements
    for i, val in ipairs(tbl) do
        val.__index = i
    end

    table.sort(tbl, function(a, b)
        if comp(a, b) then
            return true
        end
        if comp(b, a) then
            return false
        end
        -- Fallback to preserve original order
        return a.__index < b.__index
    end)

    -- Clean up temporary index
    for _, val in ipairs(tbl) do
        val.__index = nil
    end
end