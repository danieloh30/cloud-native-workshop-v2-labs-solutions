package com.redhat.coolstore;

import javax.persistence.Cacheable;
import javax.persistence.Column;
import javax.persistence.Entity;

import io.quarkus.hibernate.orm.panache.PanacheEntity;

@Entity
@Cacheable
public class Inventory extends PanacheEntity {

	@Column
    private String location;

	@Column
    private int quantity;

	@Column
    private String link;

    public Inventory() {

    }

    public Inventory(Long itemId, int quantity, String location, String link) {
        super();
        this.quantity = quantity;
        this.location = location;
        this.link = link;
    }

	public String getLocation() {
		return location;
	}

	public void setLocation(String location) {
		this.location = location;
	}

	public int getQuantity() {
		return quantity;
	}

	public void setQuantity(int quantity) {
		this.quantity = quantity;
	}

	public String getLink() {
		return link;
	}

	public void setLink(String link) {
		this.link = link;
	}

}