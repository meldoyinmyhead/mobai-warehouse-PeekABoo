-- Process stock transfer between locations
create or replace function public.process_transfer(
    p_prod_id uuid,
    p_from_loc uuid,
    p_to_loc uuid,
    p_qty int,
    p_user_id uuid
) returns jsonb as $$
declare
    v_current_qty int;
    v_trans_id uuid;
begin
    -- 0. Check stock availability with row lock
    select quantite into v_current_qty
    from public.stock_par_emplacement
    where id_produit = p_prod_id and id_emplacement = p_from_loc
    for update;

    if v_current_qty is null or v_current_qty < p_qty then
        raise exception 'Insufficient stock: needed %, available %', p_qty, coalesce(v_current_qty, 0);
    end if;

    -- 1. Decrement source stock
    update public.stock_par_emplacement
    set quantite = quantite - p_qty,
        updated_at = now(),
        version = version + 1
    where id_produit = p_prod_id and id_emplacement = p_from_loc;

    -- 2. Increment destination stock
    insert into public.stock_par_emplacement (id_produit, id_emplacement, quantite, updated_at)
    values (p_prod_id, p_to_loc, p_qty, now())
    on conflict (id_produit, id_emplacement)
    do update set 
        quantite = public.stock_par_emplacement.quantite + excluded.quantite,
        updated_at = now(),
        version = public.stock_par_emplacement.version + 1;

    -- 3. Log transaction
    insert into public.transactions (type_transaction, statut, created_at)
    values ('TRANSFER', 'COMPLETED', now())
    returning id_transaction into v_trans_id;

    insert into public.lignes_transactions (id_transaction, id_produit, quantite, id_emplacement_source, id_emplacement_destination)
    values (v_trans_id, p_prod_id, p_qty, p_from_loc, p_to_loc);

    return jsonb_build_object('status', 'SUCCESS');
end;
$$ language plpgsql security definer;

-- Process delivery validation
create or replace function public.process_delivery(
    p_order_id uuid,
    p_result varchar,
    p_notes text,
    p_user_id uuid
) returns jsonb as $$
begin
    -- 1. Update Picking Order status
    update public.picking_orders
    set statut = 'COMPLETED'
    where id = p_order_id;

    -- 2. Record delivery
    insert into public.delivery_records (id_picking_order, executed_by, resultat, notes, delivered_at)
    values (p_order_id, p_user_id, p_result, p_notes, now());

    return jsonb_build_object('status', 'SUCCESS');
end;
$$ language plpgsql security definer;
