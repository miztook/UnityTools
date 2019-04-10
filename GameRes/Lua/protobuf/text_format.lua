--
--------------------------------------------------------------------------------
--  FILE:  text_format.lua
--  DESCRIPTION:  protoc-gen-lua
--      Google's Protocol Buffers project, ported to lua.
--      https://code.google.com/p/protoc-gen-lua/
--
--      Copyright (c) 2010 , 林卓毅 (Zhuoyi Lin) netsnail@gmail.com
--      All rights reserved.
--
--      Use, modification and distribution are subject to the "New BSD License"
--      as listed at <url: http://www.opensource.org/licenses/bsd-license.php >.
--  COMPANY:  NetEase
--  CREATED:  2010年08月05日 15时14分13秒 CST
--------------------------------------------------------------------------------
--
local string = string
local math = math
local print = print
local getmetatable = getmetatable
local table = table
local ipairs = ipairs
local tostring = tostring
local pb = require "pb"

local descriptor = require "protobuf.descriptor"

module "protobuf.text_format"

function format(buffer)
    local len = string.len( buffer )	
    for i = 1, len, 16 do		
        local text = ""	
        for j = i, math.min( i + 16 - 1, len ) do	
            text = string.format( "%s  %02x", text, string.byte( buffer, j ) )			
        end			
        print( text )	
    end
end


local FieldDescriptor = descriptor.FieldDescriptor
local int64_types =
{
    [FieldDescriptor.TYPE_INT64] = true,
    [FieldDescriptor.TYPE_SFIXED64] = true,
    [FieldDescriptor.TYPE_SINT64] = true,
}
local uint64_types =
{
    [FieldDescriptor.TYPE_UINT64] = true,
    [FieldDescriptor.TYPE_FIXED64] = true,
}

msg_format_indent = function(write, msg, indent)
    for field, value in msg:ListFields() do
        local print_field = function(field_value)
            local name = field.name
            write(string.rep(" ", indent))
            if field.type == FieldDescriptor.TYPE_MESSAGE then
                local extensions = getmetatable(msg)._extensions_by_name
                if extensions[field.full_name] then
                    write("[" .. name .. "] {\n")
                else
                    write(name .. " {\n")
                end
                msg_format_indent(write, field_value, indent + 4)
                write(string.rep(" ", indent))
                write("}\n")
            else
                write(string.format("%s: ", name))
                if field.type == FieldDescriptor.TYPE_BYTES then
                    write("[")
                    for i = 1, #field_value do
                        write(("%02x"):format(field_value:byte(i)))
                    end
                    write("]")
                elseif int64_types[field.type] then
                    write(pb.int64_to_string(field_value))
                elseif uint64_types[field.type] then
                    write(pb.uint64_to_string(field_value))
                else
                    write(tostring(field_value))
                end
                write(string.format("\n"))
            end
        end
        if field.label == FieldDescriptor.LABEL_REPEATED then
            for _, k in ipairs(value) do
                print_field(k)
            end
        else
            print_field(value)
        end
    end
end

function msg_format(msg)
    local out = {}
    local write = function(value)
        out[#out + 1] = value
    end
    msg_format_indent(write, msg, 0)
    return table.concat(out)
end

