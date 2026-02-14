-- Process merchandise reception and update stock
create or replace function public.process_receipt(
    p_order_id uuid,
    p_items jsonb,
    p_user_id uuid
) returns jsonb as $$
declare
    v_item record;
    v_emplacement_id uuid;
begin
    -- 1. Find the RECEPTION zone for the warehouse
    select id_emplacement into v_emplacement_id
    from public.emplacements
    where zone = 'RECEPTION'
    limit 1;

    if v_emplacement_id is null then
        return jsonb_build_object('status', 'ERROR', 'message', 'Reception zone not found');
    end if;

    -- 2. Update order status
    update public.command_orders
    set statut = 'COMPLETED'
    where id = p_order_id;

    -- 3. Process items
    for v_item in select * from jsonb_to_recordset(p_items) as x(id_produit uuid, quantite int)
    loop
        -- Update order lines
        update public.command_order_lines
        set quantite_recue = v_item.quantite
        where id_command_order = p_order_id and id_produit = v_item.id_produit;

        -- Upsert stock in RECEPTION zone
        insert into public.stock_par_emplacement (id_produit, id_emplacement, quantite, updated_at)
        values (v_item.id_produit, v_emplacement_id, v_item.quantite, now())
        on conflict (id_produit, id_emplacement)
        do update set 
            quantite = public.stock_par_emplacement.quantite + excluded.quantite,
            updated_at = now(),
            version = public.stock_par_emplacement.version + 1;
            
        -- Log transaction
        insert into public.audit_log (id_utilisateur, action, entity_type, entity_id, payload)
        values (p_user_id, 'RECEIPT', 'COMMAND_ORDER', p_order_id, jsonb_build_object('produit', v_item.id_produit, 'qty', v_item.quantite));
    end loop;

    return jsonb_build_object('status', 'SUCCESS');
end;
$$ language plpgsql security definer;
