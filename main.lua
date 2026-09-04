-- adapted from MagicSort code --> https://github.com/acidflow-balatro/MagicSort/blob/main/MagicSort/MagicSort.lua

-- sorting method
-- queen
-- red queen
-- steel queen
-- red steel queen
-- king
-- red king
-- steel king
-- red steel king
-- garbage (sort by num ig)

local DEFAULT_SORT_PRIORITIES = {
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

local function get_sort_key(card, is_garbage)
    local default_val = 000
    local keys = { default_val, default_val, default_val, default_val }

    -- not sure how we get here but this is in the original so whatever
    if not card then
        return string.format("%03d%03d%03d03d", keys[1], keys[2], keys[3], keys[4])
    end

    -- enhancements
    if card.config and card.config.center and card.config.center.key then
        keys[1] = DEFAULT_SORT_PRIORITIES.enhancement[card.config.center.key] or default_val
    end

    -- Seal priority mapping
    if card.seal then
        keys[2] = DEFAULT_SORT_PRIORITIES.seal[card.seal] or default_val
    end

    -- Rank detection and classification
    if card.base and card.base.id then
        local rank = card.base.id

        if type(rank) == "number" then
            if rank >= 2 and rank <= 10 then
                keys[3] = DEFAULT_SORT_PRIORITIES.rank[rank] or default_val
            elseif rank == 11 then
                keys[3] = DEFAULT_SORT_PRIORITIES.rank.Jack or default_val
            elseif rank == 12 then
                keys[3] = DEFAULT_SORT_PRIORITIES.rank.Queen or default_val
            elseif rank == 13 then
                keys[3] = DEFAULT_SORT_PRIORITIES.rank.King or default_val
            elseif rank == 14 then
                keys[3] = DEFAULT_SORT_PRIORITIES.rank.Ace or default_val
            end
        elseif type(rank) == "string" then
            keys[3] = DEFAULT_SORT_PRIORITIES.rank[rank] or default_val
        end
    end

    -- Suit hierarchy processing
    if card.base and card.base.suit then
        keys[4] = DEFAULT_SORT_PRIORITIES.suit[card.base.suit] or default_val
    end

    if is_garbage then
        --return rank, suit, enhance, seal for garbage
        return string.format("%03d%03d%03d03d", keys[3], keys[4], keys[1], keys[2])
    else
        --return enhance, seal, rank, suit for royals
        return string.format("%03d%03d%03d03d", keys[1], keys[2], keys[3], keys[4])
    end
end

local function get_royal_sort(card)
    return get_sort_key(card, false)
end

local function get_garbage_sort(card)
    return get_sort_key(card, true)
end

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

    -- make three piles (queens, kings, garbage)
    -- sort the three piles using our priorities (slightly different for royals vs garbage)
    -- union the piles back together

    local queens = {}
    local kings = {}
    local garbage = {}

    -- separate into the three piles
    for _, card in ipairs(G.hand.cards) do
        if card and card.base and card.base.id then
            local sort_key
            local pile
            if card.base.id == 13 then
                sort_key = get_royal_sort(card)
                pile = kings
            elseif card.base.id == 12 then
                sort_key = get_royal_sort(card)
                pile = queens
            else
                sort_key = get_garbage_sort(card)
                pile = garbage
            end

            table.insert(pile, {
                card = card,
                key = sort_key
            })
        end
    end

    -- sort the cards
    stable_sort(queens,  function(a, b) return a.key < b.key end)
    stable_sort(kings,   function(a, b) return a.key < b.key end)
    stable_sort(garbage, function(a, b) return a.key < b.key end)

    -- build our new hand from sorted cards
    local new_cards = {}
    for _, item in ipairs(queens) do
        if item and item.card then
            table.insert(new_cards, item.card)
        end
    end

    for _, item in ipairs(kings) do
        if item and item.card then
            table.insert(new_cards, item.card)
        end
    end

    for _, item in ipairs(garbage) do
        if item and item.card then
            table.insert(new_cards, item.card)
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