local body_words = 0
local abstract_words = 0

-- # TODO: Flag to include headings in count
stringify = pandoc.utils.stringify

function Meta(meta)
    -- # TODO: get start stop header identifiers
    if meta.wordcount then
        abs_kw = stringify(meta.wordcount.abstract_at)
        abs_start_id = stringify(meta.wordcount.abstract_from)
        abs_stop_id = stringify(meta.wordcount.abstract_to)
        body_kw = stringify(meta.wordcount.body_at)
        body_start_id = stringify(meta.wordcount.body_from)
        body_stop_id = stringify(meta.wordcount.body_to)
    end
end

function count_words(para)
    local n_words = 0
    for _, item in ipairs(para.content) do
        if item.t == "Str" then
            local txt = item.text
            if txt:match("%P") or txt:find("^%[@") ~= nil then
                _, n = txt:gsub("%S+", "")
                n_words = n_words + n
            end
        end
    end
    return n_words
end

function start_stop_count(flag, id, start_id, stop_id)
    if id == start_id then
        return true
    elseif id == stop_id then
        return false
    end
    return flag
end

function Pandoc(doc)
    local count_abstract = false
    local count_body = false
    for _, b in pairs(doc.blocks) do
        if b.t == "Header" then
            count_abstract = start_stop_count(count_abstract, b.identifier, abs_start_id, abs_stop_id)
            count_body = start_stop_count(count_body, b.identifier, body_start_id, body_stop_id)
        end

        if b.t == "Para" then
            if count_abstract then
                local n = count_words(b)
                abstract_words = abstract_words + n
                -- quarto.log.output(abstract_words)
            elseif count_body then
                local n = count_words(b)
                body_words = body_words + n
                -- quarto.log.output(body_words)
            end
        end
    end

    return doc
end

-- #TODO: implementer i pandoc så jeg kan lave flags der stopper loopet så jeg ikke skal igennem alle strings i dok
function Str(str)
    if str.text:find("^" .. abs_kw) then
        return pandoc.Str(tostring(abstract_words))
    elseif str.text:find("^" .. body_kw) then
        return pandoc.Str(tostring(body_words))
    else
        return str
    end
end

return {
    { Meta = Meta },
    { Pandoc = Pandoc },
    { Str = Str }
}
